defmodule ArtemisWeb.Controller.Behaviour.BulkActions do
  @moduledoc """
  Functions to process Bulk Actions related to the resource type

  ## Router

      post "/users/bulk-actions", UserController, :index_bulk_actions

  ## Options

    use ArtemisWeb.Controller.Behaviour.BulkActions,
      bulk_actions: ArtemisWeb.UserView.available_bulk_actions(),
      permission: "users:list",
      path: &Routes.user_path(&1, :index)

  """

  @callback index_bulk_actions(map(), map()) :: any()

  defmacro __using__(options) do
    quote do
      import ArtemisWeb.Controller.Behaviour.BulkActions

      @behaviour ArtemisWeb.Controller.Behaviour.BulkActions

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

      # Allow defined `@callback`s to be overwritten

      defoverridable ArtemisWeb.Controller.Behaviour.BulkActions
    end
  end
end
