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
      {"Service ID", "service_id"},
      {"Service Name", "service_name"},
      {"Status", "status"},
      {"Severity", "severity"},
      {"Tags", "tags"},
      {"Team ID", "team_id"},
      {"Team Name", "team_name"},
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
      "service_id" => [
        label: fn _conn -> "Service ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "service_id", "Service ID")
        end,
        value: fn _conn, row -> row.service_id end
      ],
      "service_name" => [
        label: fn _conn -> "Service Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "service_name", "Service")
        end,
        value: fn _conn, row -> row.service_name end
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
      "team_name" => [
        label: fn _conn -> "Team Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "team_name", "Team")
        end,
        value: fn _conn, row -> row.team_name end
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
            to: "#{Artemis.Helpers.PagerDuty.get_pager_duty_web_url()}/incidents/#{row.source_uid}",
            target: "_blank"
          )
      ]
    ]

    content_tag(:div, class: "actions") do
      Enum.reduce(allowed_actions, [], fn action, acc ->
        case Keyword.get(action, :verify) do
          true -> [acc | Keyword.get(action, :link)]
          _ -> acc
        end
      end)
    end
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
  def get_team(%{source: "pagerduty", team_id: team_id}) do
    Artemis.Helpers.PagerDuty.get_pager_duty_team_name(team_id)
  end

  def get_team(%{team_id: team_id}), do: team_id

  @doc """
  Return teams as multi-select filter options
  """
  def get_incident_filter_team_id_options() do
    Artemis.Helpers.PagerDuty.get_pager_duty_teams()
    |> filter_team_id_options()
    |> Enum.reverse()
  end

  defp filter_team_id_options(teams) do
    Enum.reduce(teams, [], fn team, acc ->
      id = Keyword.get(team, :id)
      name = Keyword.get(team, :name)
      entry = [key: name, value: id]

      case Artemis.Helpers.present?(id) && Artemis.Helpers.present?(name) do
        true -> [entry | acc]
        false -> acc
      end
    end)
  end
end
