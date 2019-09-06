defmodule ArtemisWeb.SessionView do
  use ArtemisWeb, :view

  use Phoenix.HTML

  def render_session_user_name(session_entries) do
    session_entries
    |> List.first()
    |> Map.get(:user_name)
  end

  def render_session_user_link(conn, session_entries) do
    record = List.first(session_entries)
    user_name = Map.get(record, :user_name)
    user_id = Map.get(record, :user_id)

    link(user_name, to: Routes.user_path(conn, :show, user_id))
  end

  def render_session_duration(session_entries) when length(session_entries) < 2, do: nil

  def render_session_duration(session_entries) do
    first =
      session_entries
      |> List.first()
      |> Map.get(:inserted_at)

    last =
      session_entries
      |> List.last()
      |> Map.get(:inserted_at)

    render_time_duration(first, last)
  end

  def render_session_start(session_entries) do
    session_entries
    |> List.first()
    |> Map.get(:inserted_at)
    |> render_date_time()
  end

  def render_session_last(session_entries) do
    session_entries
    |> List.last()
    |> Map.get(:inserted_at)
    |> render_date_time()
  end

  def render_session_timeline(conn, session_entries) do
    content_tag(:ul, class: "timeline") do
      render_session_timeline_entries(conn, session_entries)
    end
  end

  defp render_session_timeline_entries(conn, entries) do
    Enum.map(entries, fn entry ->
      content_tag(:li) do
        render_session_entry(conn, entry)
      end
    end)
  end

  defp render_session_entry(conn, %ArtemisLog.EventLog{} = entry) do
    identifier = Artemis.Helpers.deep_get(entry, [:meta, "name"]) || Map.get(entry, :resource_id)
    summary = get_summary(entry.action)
    icon = get_icon(entry.action)
    class = if icon, do: "with-icon", else: "without-icon"

    assigns = [
      class: class,
      color: get_color(entry.action),
      conn: conn,
      entry: entry,
      icon: icon,
      summary: "#{summary} #{identifier}"
    ]

    render("_timeline_entry_event_log.html", assigns)
  end

  defp render_session_entry(conn, %ArtemisLog.HttpRequestLog{} = entry) do
    action = "page:visited"
    summary = get_summary(action)
    icon = get_icon(action)
    class = if icon, do: "with-icon", else: "without-icon"

    assigns = [
      class: class,
      color: get_color(action),
      conn: conn,
      entry: entry,
      icon: icon,
      summary: summary
    ]

    render("_timeline_entry_http_request_log.html", assigns)
  end

  defp get_icon(value) when is_bitstring(value) do
    cond do
      String.match?(value, ~r/.*created.*/) -> "plus"
      String.match?(value, ~r/.*updated.*/) -> "pencil"
      String.match?(value, ~r/.*deleted.*/) -> "trash"
      true -> nil
    end
  end

  defp get_color(value) when is_bitstring(value) do
    cond do
      String.match?(value, ~r/.*created.*/) -> "blue"
      String.match?(value, ~r/.*updated.*/) -> "green"
      String.match?(value, ~r/.*deleted.*/) -> "red"
      true -> nil
    end
  end

  defp get_summary(value) when is_bitstring(value) do
    value
    |> String.split(":")
    |> Enum.take(2)
    |> Enum.map(&String.replace(&1, "-", " "))
    |> Enum.map(&Artemis.Helpers.titlecase(&1))
    |> Enum.reverse()
    |> Enum.join(" ")
  end
end
