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
      render_async(conn, ArtemisWeb.EventLogView, "index",
        async_data: fn callback_pid, _assigns ->
          user = current_user(conn)
          event_logs = ListEventLogs.call_with_cache_then_update(params, user, callback_pid: callback_pid)

          [
            default_columns: @default_columns,
            event_logs: event_logs.data
          ]
        end
      )
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "event-logs:show", fn ->
      event_log = GetEventLog.call!(id, current_user(conn))

      render(conn, "show.html", event_log: event_log)
    end)
  end
end
