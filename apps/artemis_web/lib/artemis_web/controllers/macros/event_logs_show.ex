defmodule ArtemisWeb.Controller.EventLogsShow do
  @moduledoc """
  Functions to show Event Logs related to the resource type and instance.

  ## Routing Requests

  The suggested way to route requests is by defining four new routes.

  Given a typical resource:

      resources "/permissions", PermissionController

  Add the following routes:

      resources "/permissions", PermissionController do
        get "/event-logs", PermissionController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", PermissionController, :show_event_log_details, as: :event_log
      end

  ## Controllers

      use ArtemisWeb.Controller.EventLogsShow,
        path: &Routes.permission_event_log_path/4,
        permission: "permissions:show",
        resource_getter: &Artemis.GetPermission.call!/2,
        resource_id: "permission_id",
        resource_type: "Permission",
        resource_variable: :permission

  ## Templates

  Requires the following phoenix templates to be present:

      templates/permissions/show/event_log_details.ex
      templates/permissions/show/event_log_list.ex

  Note: this may require adding support for nested template directories using
  the `pattern: "**/*"` option:

      use Phoenix.View,
        root: "lib/artemis_web/templates",
        namespace: ArtemisWeb,
        pattern: "**/*"

  """

  defmacro __using__(options) do
    quote do
      def show_event_log_list(conn, params) do
        settings = unquote(options)
        path = Keyword.fetch!(settings, :path)
        permission = Keyword.fetch!(settings, :permission)
        resource_getter = Keyword.fetch!(settings, :resource_getter)
        resource_id = Keyword.fetch!(settings, :resource_id)
        resource_type = Keyword.fetch!(settings, :resource_type)
        resource_variable = Keyword.get(settings, :resource_variable, :resource)

        authorize(conn, permission, fn ->
          id = Map.get(params, resource_id)
          resource = resource_getter.(id, current_user(conn))

          options = [
            path: path,
            resource_id: id,
            resource_type: resource_type
          ]

          assigns =
            conn
            |> get_assigns_for_show_event_log_list(params, options)
            |> Keyword.put(resource_variable, resource)

          render_format_for_event_log_list_show(conn, "show/event_log_list.html", assigns)
        end)
      end

      def show_event_log_details(conn, params) do
        settings = unquote(options)
        permission = Keyword.fetch!(settings, :permission)
        resource_getter = Keyword.fetch!(settings, :resource_getter)
        resource_id = Keyword.fetch!(settings, :resource_id)
        resource_type = Keyword.fetch!(settings, :resource_type)
        resource_variable = Keyword.get(settings, :resource_variable, :resource)

        authorize(conn, permission, fn ->
          id = Map.get(params, resource_id)
          resource = resource_getter.(id, current_user(conn))

          event_log_id = Map.get(params, "id")
          event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

          assigns =
            []
            |> Keyword.put(:event_log, event_log)
            |> Keyword.put(resource_variable, resource)

          render(conn, "show/event_log_details.html", assigns)
        end)
      end

      # Helpers - Assigns

      defp get_assigns_for_show_event_log_list(conn, params, options) do
        path = Keyword.get(options, :path)
        resource_id = Keyword.get(options, :resource_id)
        resource_type = Keyword.get(options, :resource_type)

        event_log_filters = %{
          "resource_id" => resource_id,
          "resource_type" => resource_type
        }

        event_log_params = Artemis.Helpers.deep_merge(params, %{"filters" => event_log_filters})
        event_logs = ArtemisLog.ListEventLogs.call(event_log_params, current_user(conn))

        allowed_column_options = [
          to: fn conn, id -> path.(conn, :show_event_log_details, resource_id, id) end
        ]

        allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)
        default_columns = ["action", "user_name", "reason", "inserted_at"]

        pagination_options = [
          action: :show_event_log_list,
          path: fn conn, page, options -> path.(conn, page, resource_id, options) end
        ]

        [
          allowed_columns: allowed_columns,
          conn: conn,
          default_columns: default_columns,
          event_logs: event_logs,
          pagination_options: pagination_options
        ]
      end

      # Helpers - Render

      @doc """
      Renders the correct event log template

      Supports `csv` and the default `html` formats.
      """
      def render_format_for_event_log_list_show(conn, template, assigns) do
        case get_format(conn) do
          "csv" ->
            conn
            |> put_view(ArtemisWeb.EventLogView)
            |> render_format("index", assigns)

          _ ->
            render(conn, template, assigns)
        end
      end
    end
  end
end
