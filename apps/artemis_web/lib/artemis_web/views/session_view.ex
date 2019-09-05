defmodule ArtemisWeb.SessionView do
  use ArtemisWeb, :view

  use Phoenix.HTML

  def render_session_timeline(event_logs, session_logs) do
    IO.inspect(event_logs)
    IO.inspect(session_logs)

    combined = event_logs ++ session_logs
    sorted = Enum.sort_by(combined, & &1.inserted_at)
    reversed = Enum.reverse(sorted)

    Enum.map(reversed, fn entry ->
      content_tag(:ul) do
        content_tag(:li) do
          render_session_entry(entry)
        end
      end
    end)
  end

  defp render_session_entry(%ArtemisLog.EventLog{} = entry) do
    content_tag(:div) do
      [
        content_tag(:span, entry.inserted_at),
        content_tag(:span, " - "),
        content_tag(:span, entry.action)
      ]
    end
  end

  defp render_session_entry(%ArtemisLog.HttpRequestLog{} = entry) do
    content_tag(:div) do
      [
        content_tag(:span, entry.inserted_at),
        content_tag(:span, " - "),
        content_tag(:span, entry.path)
      ]
    end
  end
end
