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
      user = current_user(conn)
      http_request_logs = ListHttpRequestLogs.call(params, user)
      filter_paths = ListHttpRequestLogs.call(%{distinct: :path}, user)
      filter_session_ids = ListHttpRequestLogs.call(%{distinct: :session_id}, user)
      filter_user_ids = ListHttpRequestLogs.call(%{distinct: :user_id}, user)
      filter_user_names = ListHttpRequestLogs.call(%{distinct: :user_name}, user)

      assigns = [
        default_columns: @default_columns,
        filter_paths: filter_paths,
        filter_session_ids: filter_session_ids,
        filter_user_ids: filter_user_ids,
        filter_user_names: filter_user_names,
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
