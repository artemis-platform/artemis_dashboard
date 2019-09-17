defmodule ArtemisWeb.HttpRequestLogController do
  use ArtemisWeb, :controller

  alias ArtemisLog.GetHttpRequestLog
  alias ArtemisLog.ListHttpRequestLogs

  @default_columns [
    "id",
    "path",
    "user_name",
    "inserted_at",
    "actions"
  ]

  def index(conn, params) do
    authorize(conn, "http-request-logs:list", fn ->
      http_request_logs = ListHttpRequestLogs.call(params, current_user(conn))

      assigns = [
        default_columns: @default_columns,
        http_request_logs: http_request_logs
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "http-request-logs:show", fn ->
      http_request_log = GetHttpRequestLog.call!(id, current_user(conn))

      render(conn, "show.html", http_request_log: http_request_log)
    end)
  end
end
