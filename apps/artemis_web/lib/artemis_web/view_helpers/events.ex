defmodule ArtemisWeb.ViewHelper.Events do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Render event log list
  """
  def render_event_log_list(conn_or_assigns, event_logs, options \\ []) do
    options = get_event_log_list_options(conn_or_assigns, options)

    assigns = [
      allowed_columns: Keyword.fetch!(options, :allowed_columns),
      conn_or_socket: Keyword.fetch!(options, :conn_or_socket),
      default_columns: Keyword.get(options, :default_columns, []),
      event_logs: event_logs,
      pagination_options: Keyword.get(options, :pagination_options, []),
      query_params: Keyword.fetch!(options, :query_params),
      request_path: Keyword.fetch!(options, :request_path),
      user: Keyword.fetch!(options, :user)
    ]

    Phoenix.View.render(ArtemisWeb.EventLogView, "_list.html", assigns)
  end

  defp get_event_log_list_options(%Plug.Conn{} = conn, options) do
    options
    |> Keyword.put_new(:conn_or_socket, conn)
    |> Keyword.put_new(:query_params, conn.query_params)
    |> Keyword.put_new(:request_path, conn.request_path)
    |> Keyword.put_new(:user, current_user(conn))
  end

  defp get_event_log_list_options(assigns, options) do
    conn_or_socket = Map.get(assigns, :conn) || Map.get(assigns, :socket)

    options
    |> Keyword.put_new(:conn_or_socket, conn_or_socket)
    |> Keyword.put_new(:query_params, Map.get(assigns, :query_params))
    |> Keyword.put_new(:request_path, Map.get(assigns, :request_path))
    |> Keyword.put_new(:user, Map.get(assigns, :user))
  end

  @doc """
  Render event log details
  """
  def render_event_log_details(conn, event_log) do
    assigns = [
      conn: conn,
      event_log: event_log
    ]

    Phoenix.View.render(ArtemisWeb.EventLogView, "_record.html", assigns)
  end
end
