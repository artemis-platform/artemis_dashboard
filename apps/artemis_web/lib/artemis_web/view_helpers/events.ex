defmodule ArtemisWeb.ViewHelper.Events do
  use Phoenix.HTML

  @doc """
  Render event log list
  """
  def render_event_log_list(conn, event_logs, options \\ []) do
    assigns = [
      allowed_columns: Keyword.get(options, :allowed_columns),
      conn: conn,
      default_columns: Keyword.get(options, :default_columns, []),
      event_logs: event_logs,
      pagination_options: Keyword.get(options, :pagination_options, [])
    ]

    Phoenix.View.render(ArtemisWeb.EventLogView, "_list.html", assigns)
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
