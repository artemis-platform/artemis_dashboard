defmodule ArtemisWeb.Controller.EventLogs do
  @moduledoc """
  Functions to show Event Logs related to the resource type and the resource
  instance.
  """

  @callback index_event_log_list(map(), map()) :: any()
  @callback index_event_log_details(map(), map()) :: any()
  @callback show_event_log_list(map(), map()) :: any()
  @callback show_event_log_details(map(), map()) :: any()

  defmacro __using__(_options) do
    quote do
      import ArtemisWeb.Controller.EventLogs

      @behaviour ArtemisWeb.Controller.EventLogs

      # Helpers - Assigns

      defp get_assigns_for_index_event_log_list(conn, params) do
        event_log_filters = %{"resource_type" => "Customer"}
        event_log_params = Artemis.Helpers.deep_merge(params, %{"filters" => event_log_filters})
        event_logs = ArtemisLog.ListEventLogs.call(event_log_params, current_user(conn))

        allowed_column_options = [
          to: fn conn, id ->
            ArtemisWeb.Router.Helpers.customer_path(conn, :index_event_log_details, id)
          end
        ]

        allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)
        default_columns = ["action", "resource_id", "user_name", "inserted_at"]

        pagination_options = [
          action: :index_event_log_list,
          path: &ArtemisWeb.Router.Helpers.customer_path/3
        ]

        assigns = [
          allowed_columns: allowed_columns,
          conn: conn,
          default_columns: default_columns,
          event_logs: event_logs,
          pagination_options: pagination_options
        ]
      end

      defp get_assigns_for_show_event_log_list(conn, params) do
        resource_id = Map.get(params, "customer_id")

        event_log_filters = %{"resource_type" => "Customer", "resource_id" => resource_id}
        event_log_params = Artemis.Helpers.deep_merge(params, %{"filters" => event_log_filters})
        event_logs = ArtemisLog.ListEventLogs.call(event_log_params, current_user(conn))

        allowed_column_options = [
          to: fn conn, id ->
            ArtemisWeb.Router.Helpers.customer_event_log_path(conn, :show_event_log_details, resource_id, id)
          end
        ]

        allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)
        default_columns = ["action", "user_name", "inserted_at"]

        pagination_options = [
          action: :show_event_log_list,
          path: fn conn, page, options ->
            ArtemisWeb.Router.Helpers.customer_event_log_path(conn, page, resource_id, options)
          end
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
      def render_format_for_event_log_list(conn, template, assigns) do
        case get_format(conn) do
          "csv" ->
            conn
            |> put_view(ArtemisWeb.EventLogView)
            |> render_format("index", assigns)

          _ ->
            render(conn, template, assigns)
        end
      end

      # Allow defined `@callback`s to be overwritten

      defoverridable ArtemisWeb.Controller.EventLogs
    end
  end
end
