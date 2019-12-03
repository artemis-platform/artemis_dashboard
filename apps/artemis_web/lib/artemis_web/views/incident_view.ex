defmodule ArtemisWeb.IncidentView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    []
  end

  def allowed_bulk_actions(user) do
    Enum.reduce(available_bulk_actions(), [], fn entry, acc ->
      case entry.authorize.(user) do
        true -> [entry | acc]
        false -> acc
      end
    end)
  end

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Date", "triggered_at"},
      {"Incident", "source_uid"},
      {"Status", "status"},
      {"Severity", "severity"},
      {"Tags", "tags"},
      {"Team ID", "team_id"},
      {"Title", "title"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "severity" => [
        label: fn _conn -> "Severity" end,
        label_html: fn conn ->
          sortable_table_header(conn, "severity", "Severity")
        end,
        value: fn _conn, row -> row.severity end
      ],
      "source_uid" => [
        label: fn _conn -> "Incident" end,
        label_html: fn conn ->
          sortable_table_header(conn, "source_uid", "Incident")
        end,
        value: fn _conn, row -> row.source_uid end,
        value_html: fn conn, row ->
          case has?(conn, "incidents:show") do
            true -> link(row.source_uid, to: Routes.incident_path(conn, :show, row))
            false -> row.source_uid
          end
        end
      ],
      "status" => [
        label: fn _conn -> "Status" end,
        label_html: fn conn ->
          sortable_table_header(conn, "status", "Status")
        end,
        value: fn _conn, row -> row.status end,
        value_html: fn _conn, row ->
          content_tag(:span, class: "status-label #{status_color(row)}") do
            row.status
          end
        end
      ],
      "tags" => [
        label: fn _conn -> "Tags" end,
        value: fn _conn, row ->
          row.tags
          |> Enum.map(&Map.get(&1, :name))
          |> Enum.sort()
          |> Enum.join(", ")
        end,
        value_html: &render_tags/2
      ],
      "team_id" => [
        label: fn _conn -> "Team ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "team_id", "Team ID")
        end,
        value: fn _conn, row -> row.team_id end
      ],
      "title" => [
        label: fn _conn -> "Title" end,
        label_html: fn conn ->
          sortable_table_header(conn, "title", "Title")
        end,
        value: fn _conn, row -> row.title end
      ],
      "triggered_at" => [
        label: fn _conn -> "Date" end,
        label_html: fn conn ->
          sortable_table_header(conn, "triggered_at", "Date")
        end,
        value: fn _conn, row -> row.triggered_at end,
        value_html: fn _conn, row -> render_date_time(row.triggered_at) end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "incidents:show"),
        link: link("Show", to: Routes.incident_path(conn, :show, row))
      ],
      [
        verify: row.source == "pagerduty",
        link:
          link("View on PagerDuty",
            to: "#{get_pager_duty_web_url()}/incidents/#{row.source_uid}",
            target: "_blank"
          )
      ]
    ]

    Enum.reduce(allowed_actions, [], fn action, acc ->
      case Keyword.get(action, :verify) do
        true -> [acc | Keyword.get(action, :link)]
        _ -> acc
      end
    end)
  end

  # Helpers

  def render_tags(conn, incident) do
    Enum.map(incident.tags, fn tag ->
      to = Routes.incident_path(conn, :index, filters: %{tags: [tag.slug]})

      content_tag(:div) do
        link(tag.name, to: to)
      end
    end)
  end

  def get_pager_duty_web_url(), do: Application.fetch_env!(:artemis, :pager_duty)[:web_url]

  @doc """
  Render status
  """
  def render_status(incident) do
    content_tag(:p) do
      content_tag(:span, class: "status-label #{status_color(incident)}") do
        incident.status
      end
    end
  end

  def status_color(%{status: status}) when is_bitstring(status) do
    case String.downcase(status) do
      "resolved" -> "green"
      "acknowledged" -> "yellow"
      "triggered" -> "red"
      true -> nil
    end
  end

  def status_color(_), do: nil

  @doc """
  Display a user friendly team value depending on incident type
  """
  def get_team(%{source: "pagerduty"} = team) do
    team =
      Enum.find(get_pager_duty_teams(), fn entry ->
        Keyword.get(entry, :id) == team.team_id
      end) || []

    Keyword.get(team, :name)
  end

  def get_team(%{team_id: team_id}), do: team_id

  defp get_pager_duty_teams() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
  end

  @doc """
  Return teams as multi-select filter options
  """
  def get_incident_filter_team_id_options() do
    Enum.map(get_pager_duty_teams(), fn team ->
      [
        key: Keyword.get(team, :name),
        value: Keyword.get(team, :id)
      ]
    end)
  end
end
