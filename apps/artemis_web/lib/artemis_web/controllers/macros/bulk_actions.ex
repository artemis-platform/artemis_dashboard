defmodule ArtemisWeb.Controller.BulkActions do
  @moduledoc """
  Functions to process Bulk Actions related to the resource type

  ## Router

      post "/users/bulk-actions", UserController, :index_bulk_actions

  ## Options

      use ArtemisWeb.Controller.BulkActions,
        bulk_actions: ArtemisWeb.UserView.available_bulk_actions(),
        permission: "users:list",
        path: &Routes.user_path(&1, :index)

  """

  defmacro __using__(options) do
    quote do
      def index_bulk_actions(conn, params) do
        settings = unquote(options)

        bulk_actions = Keyword.fetch!(settings, :bulk_actions)
        path = Keyword.fetch!(settings, :path)
        permission = Keyword.fetch!(settings, :permission)

        authorize(conn, permission, fn ->
          ids = Map.get(params, "ids") || []
          key = Map.get(params, "bulk_action")
          user = current_user(conn)
          return_path = Map.get(params, "return_path", path.(conn))

          bulk_action =
            Enum.find_value(bulk_actions, fn entry ->
              entry.key == key && entry.authorize.(user) && entry.action
            end)

          result = bulk_action.(ids, [params, user])
          total_errors = length(result.errors)

          case total_errors == 0 do
            true ->
              conn
              |> put_flash(:info, "Successfully completed bulk #{key} action on #{length(result.data)} records")
              |> redirect(to: return_path)

            false ->
              message = "Error completing bulk #{key} action. Failed on #{total_errors} of #{length(ids)} records."

              conn
              |> put_flash(:error, message)
              |> redirect(to: return_path)
          end
        end)
      end
    end
  end
end
