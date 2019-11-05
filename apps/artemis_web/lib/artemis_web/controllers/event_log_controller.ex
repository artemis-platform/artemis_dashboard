defmodule ArtemisWeb.EventLogController do
  use ArtemisWeb, :controller

  alias ArtemisLog.GetEventLog
  alias ArtemisLog.ListEventLogs

  @default_columns [
    "resource_type",
    "action",
    "user_name",
    "reason",
    "inserted_at",
    "actions"
  ]

  def index(conn, params) do
    authorize(conn, "event-logs:list", fn ->
      event_logs = ListEventLogs.call(params, current_user(conn))

      assigns = [
        default_columns: @default_columns,
        event_logs: event_logs
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "event-logs:show", fn ->
      event_log = GetEventLog.call!(id, current_user(conn))

      render(conn, "show.html", event_log: event_log)
    end)
  end
end
