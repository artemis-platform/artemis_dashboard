defmodule ArtemisWeb.Controller.EventLogsIndex do
  @moduledoc """
  Functions to list Event Logs related to the resource type.

  ## Setup

  ### Router

  The suggested way to route requests is by defining two new routes.

  Given a typical resource:

      resources "/permissions", PermissionController

  Add the following routes:

      get "/permissions/event-logs", PermissionController, :index_event_log_list
      get "/permissions/event-logs/:id", PermissionController, :index_event_log_details
      resources "/permissions", PermissionController

  ## Controller

      use ArtemisWeb.Controller.EventLogsIndex,
        path: &Routes.permission_path/3,
        permission: "permissions:list",
        resource_type: "Permission"

  ## Templates

  Requires the following phoenix templates to be present:

      templates/permissions/index/event_log_details.ex
      templates/permissions/index/event_log_list.ex

  Note: this may require adding support for nested template directories using
  the `pattern: "**/*"` option:

      use Phoenix.View,
        root: "lib/artemis_web/templates",
        namespace: ArtemisWeb,
        pattern: "**/*"

  """

  defmacro __using__(options) do
    quote do
      def index_event_log_list(conn, params) do
        settings = unquote(options)
        path = Keyword.fetch!(settings, :path)
        permission = Keyword.fetch!(settings, :permission)
        resource_type = Keyword.fetch!(settings, :resource_type)

        authorize(conn, permission, fn ->
          options = [
            path: path,
            resource_type: resource_type
          ]

          assigns = get_assigns_for_index_event_log_list(conn, params, options)

          render_format_for_event_log_list_index(conn, "index/event_log_list.html", assigns)
        end)
      end

      def index_event_log_details(conn, %{"id" => id}) do
        settings = unquote(options)
        permission = Keyword.fetch!(settings, :permission)

        authorize(conn, permission, fn ->
          event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

          render(conn, "index/event_log_details.html", event_log: event_log)
        end)
      end

      # Helpers - Assigns

      defp get_assigns_for_index_event_log_list(conn, params, options) do
        path = Keyword.get(options, :path)
        resource_type = Keyword.get(options, :resource_type)

        event_log_filters = %{
          "resource_type" => resource_type
        }

        event_log_params = Artemis.Helpers.deep_merge(params, %{"filters" => event_log_filters})
        event_logs = ArtemisLog.ListEventLogs.call(event_log_params, current_user(conn))

        allowed_column_options = [
          to: fn conn, id -> path.(conn, :index_event_log_details, id) end
        ]

        allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)
        default_columns = ["action", "resource_id", "user_name", "reason", "inserted_at"]

        pagination_options = [
          action: :index_event_log_list,
          path: path
        ]

        assigns = [
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
      def render_format_for_event_log_list_index(conn, template, assigns) do
        case get_format(conn) do
          "csv" ->
            conn
            |> put_view(ArtemisWeb.EventLogView)
            |> render_format("index", assigns)

          _ ->
            render(conn, template, assigns)
        end
      end

      # Overridable Functions

      defoverridable [
        index_event_log_details: 2,
        index_event_log_list: 2
      ]
    end
  end
end
