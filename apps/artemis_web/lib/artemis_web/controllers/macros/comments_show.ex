defmodule ArtemisWeb.Controller.CommentsShow do
  @moduledoc """
  Functions to list Comments related to the resource.

  ## Setup

  ### Router

  The suggested way to route requests is by defining two new routes.

  Given a typical resource:

      resources "/permissions", PermissionController

  Add the following routes:

      resources "/customers", CustomerController do
        get "/comments", CustomerController, :index_comment, as: :comment
        post "/comments", CustomerController, :create_comment, as: :comment
        get "/comments/:id/edit", CustomerController, :edit_comment, as: :comment
        patch "/comments/:id", CustomerController, :update_comment, as: :comment
        put "/comments/:id", CustomerController, :update_comment, as: :comment
        delete "/comments/:id", CustomerController, :delete_comment, as: :comment
      end

  ### Controllers

      use ArtemisWeb.Controller.Comments,
        path: &Routes.customer_path/3,
        permission: "customers:list",
        resource_getter: &Artemis.GetCustomer.call!/2,
        resource_id_key: "customer_id",
        resource_type: "Customer",
        resource_variable: :customer

  ### Templates

  Requires the following phoenix templates to be present:

      templates/permissions/show/comments.ex

  Note: this may require adding support for nested template directories using
  the `pattern: "**/*"` option:

      use Phoenix.View,
        root: "lib/artemis_web/templates",
        namespace: ArtemisWeb,
        pattern: "**/*"

  """

  defmacro __using__(options) do
    quote do
      def index_comment(conn, params) do
        authorize(conn, fetch_comments_show_option!(:permission), fn ->
          assigns = get_assigns_for_comments_show(conn, params)

          render(conn, "show/comment_list.html", assigns)
        end)
      end

      def create_comment(conn, params) do
        authorize(conn, fetch_comments_show_option!(:permission), fn ->
          resource_type = fetch_comments_show_option!(:resource_type)
          resource_id = get_comments_show_resource_id(params)
          user = current_user(conn)

          create_params =
            params
            |> Map.get("comment", %{})
            |> Map.put("resource_type", resource_type)
            |> Map.put("resource_id", resource_id)
            |> Map.put("user_id", user.id)

          case Artemis.CreateComment.call(create_params, user) do
            {:ok, _comment} ->
              conn
              |> put_flash(:info, "Successfully created comment")
              |> redirect(to: get_comments_show_path(conn, params))

            {:error, %Ecto.Changeset{} = comment_changeset} ->
              assigns =
                conn
                |> get_assigns_for_comments_show(params)
                |> Keyword.put(:comment_changeset, comment_changeset)

              render(conn, "show/comment_list.html", assigns)
          end
        end)
      end

      def edit_comment(conn, %{"id" => id} = params) do
        authorize(conn, fetch_comments_show_option!(:permission), fn ->
          user = current_user(conn)
          comment = Artemis.GetComment.call!(id, user)
          comment_changeset = Artemis.Comment.changeset(comment)

          assigns =
            conn
            |> get_assigns_for_comments_show(params)
            |> Keyword.put(:comment, comment)
            |> Keyword.put(:comment_changeset, comment_changeset)

          render(conn, "show/comment_edit.html", assigns)
        end)
      end

      def update_comment(conn, %{"id" => id} = params) do
        authorize(conn, fetch_comments_show_option!(:permission), fn ->
          user = current_user(conn)
          comment = Artemis.GetComment.call!(id, user)
          resource_type = fetch_comments_show_option!(:resource_type)
          resource_id = get_comments_show_resource_id(params)

          update_params =
            params
            |> Map.get("comment", %{})
            |> Map.put("resource_type", resource_type)
            |> Map.put("resource_id", resource_id)
            |> Map.put("user_id", user.id)

          case Artemis.UpdateComment.call(id, update_params, user) do
            {:ok, _comment} ->
              conn
              |> put_flash(:info, "Successfully updated comment")
              |> redirect(to: get_comments_show_path(conn, params))

            {:error, %Ecto.Changeset{} = changeset} ->
              assigns =
                conn
                |> get_assigns_for_comments_show(params)
                |> Keyword.put(:comment, comment)
                |> Keyword.put(:comment_changeset, changeset)

              render(conn, "show/comment_edit.html", assigns)
          end
        end)
      end

      # TODO recheck ownership and permissions before delete
      def delete_comment(conn, %{"id" => id} = params) do
        authorize(conn, fetch_comments_show_option!(:permission), fn ->
          {:ok, _comment} = Artemis.DeleteComment.call(id, current_user(conn))

          conn
          |> put_flash(:info, "Successfully deleted comment")
          |> redirect(to: get_comments_show_path(conn, params))
        end)
      end

      # Helpers - Assigns

      defp get_assigns_for_comments_show(conn, params) do
        resource_id = get_comments_show_resource_id(params)
        resource_type = fetch_comments_show_option!(:resource_type)

        comment_filters = %{
          "resource_id" => resource_id,
          "resource_type" => resource_type
        }

        comment_params = Artemis.Helpers.deep_merge(params, %{"filters" => comment_filters})
        comments = Artemis.ListComments.call(comment_params, current_user(conn))
        comment_changeset = Artemis.Comment.changeset(%Artemis.Comment{})
        comment_create_action = get_comments_show_path(conn, params)
        comment_edit_action = fn id -> "#{get_comments_show_path(conn, params, id)}/edit" end
        comment_delete_action = fn id -> get_comments_show_path(conn, params, id) end
        comment_update_action = fn id -> get_comments_show_path(conn, params, id) end

        resource_variable = get_comments_show_option_resource_variable()
        resource = get_comments_show_resource(params, current_user(conn))

        assigns = [
          comment_changeset: comment_changeset,
          comment_edit_action: comment_edit_action,
          comment_create_action: comment_create_action,
          comment_delete_action: comment_delete_action,
          comment_update_action: comment_update_action,
          comment_resource: resource,
          comment_resource_type: resource_type,
          comments: comments,
          conn: conn
        ]

        Keyword.put(assigns, resource_variable, resource)
      end

      # Helpers - Options

      defp fetch_comments_show_option!(key), do: Keyword.fetch!(unquote(options), key)

      defp get_comments_show_option(key, default \\ nil), do: Keyword.get(unquote(options), key, default)

      defp get_comments_show_option_resource_variable() do
        resource_type = fetch_comments_show_option!(:resource_type)

        resource_variable_default =
          resource_type
          |> Artemis.Helpers.snakecase()
          |> String.to_atom()

        get_comments_show_option(:resource_variable, resource_variable_default)
      end

      # Helpers - Params

      defp get_comments_show_resource(params, user) do
        resource_getter = fetch_comments_show_option!(:resource_getter)
        id = get_comments_show_resource_id(params)

        resource_getter.(id, user)
      end

      defp get_comments_show_resource_id(params) do
        resource_id_key = fetch_comments_show_option!(:resource_id_key)

        Map.get(params, resource_id_key)
      end

      defp get_comments_show_path(conn, params, id \\ nil) do
        path = fetch_comments_show_option!(:path)
        resource_id = get_comments_show_resource_id(params)

        "#{path.(conn, :show, resource_id)}/comments/#{id}"
      end

      # Overridable Functions

      defoverridable index_comment: 2,
                     create_comment: 2,
                     update_comment: 2,
                     delete_comment: 2
    end
  end
end
