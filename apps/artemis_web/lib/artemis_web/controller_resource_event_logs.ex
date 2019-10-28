defmodule ArtemisWeb.Controller.ResourceEventLogs do
  @moduledoc """
  Functions to show Event Logs related to the resource type and the resource
  instance.
  """

  defmacro __using__(options) do
    quote do
      def event_log_index(conn, params) do
        # TODO: how to handle authorization? Maybe by `options`
        authorize(conn, "customers:list", fn ->
          user = current_user(conn)
          resource_name = Keyword.get(unquote(options), :resource_name)

          resource_type =
            unquote(options)
            |> Keyword.get(:resource_type)
            |> Artemis.Helpers.module_name()
            |> Artemis.Helpers.to_string()

          resource_id =
            Enum.find_value(params, fn {key, value} ->
              case String.match?(key, ~r/.*_id$/) do
                false -> nil
                true -> value
              end
            end)

          default_columns =
            case resource_id do
              nil -> ["action", "resource_id", "user_name", "inserted_at"]
              _ -> ["action", "user_name", "inserted_at"]
            end

          resource_type_filter = %{"filters" => %{"resource_type" => resource_type}}

          resource_id_filter =
            case resource_id do
              nil -> %{}
              value -> %{"filters" => %{"resource_id" => value}}
            end

          event_log_params =
            params
            |> Artemis.Helpers.deep_merge(resource_type_filter)
            |> Artemis.Helpers.deep_merge(resource_id_filter)
            # TODO: temporary for debugging, remove.
            |> Artemis.Helpers.deep_merge(%{"page_size" => "1"})

          event_logs = ArtemisLog.ListEventLogs.call(event_log_params, user)

          allowed_column_options = [
            to: fn conn, id ->
              case resource_id do
                nil -> ArtemisWeb.Router.Helpers.customer_path(conn, :event_log_show, id)
                _ -> ArtemisWeb.Router.Helpers.customer_customer_path(conn, :event_log_show, resource_id, id)
              end
            end
          ]

          allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)

          pagination_options = [
            action: :event_log_index,
            path: case resource_id do
              nil -> &ArtemisWeb.Router.Helpers.customer_path/3
              _ -> fn conn, page, options ->
                ArtemisWeb.Router.Helpers.customer_customer_path(conn, page, resource_id, options)
              end
            end
          ]

          assigns = [
            allowed_columns: allowed_columns,
            conn: conn,
            default_columns: default_columns,
            event_logs: event_logs,
            pagination_options: pagination_options,
            resource_name: resource_name,
            resource_type: resource_type
          ]

          conn
          |> put_view(ArtemisWeb.LayoutView)
          |> render("resource_event_logs.html", assigns)
        end)
      end

      def event_log_show(conn, params) do
        authorize(conn, "customers:list", fn ->
          resource_id = Enum.find_value(params, fn {key, value} ->
            case String.match?(key, ~r/.*_id$/) do
              false -> nil
              true -> value
            end
          end)

          assigns = [
            conn: conn,
            default_columns: ["action", "user_name", "inserted_at"],
            event_logs: ArtemisLog.ListEventLogs.call(params, current_user(conn))
          ]

          conn
          |> put_view(ArtemisWeb.LayoutView)
          |> render("resource_event_logs.html", assigns)
        end)
      end

      # Helpers

      defp get_event_logs(params, _user) do
        # TODO: move this into a liveview helper?
        # TODO: detect when an `*_id` field is passed
        "hello world - index"
      end
    end
  end
end
