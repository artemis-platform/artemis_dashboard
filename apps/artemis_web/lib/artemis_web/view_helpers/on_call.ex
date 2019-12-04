defmodule ArtemisWeb.ViewHelper.OnCall do
  use Phoenix.HTML

  import ArtemisWeb.UserAccess

  @doc """
  Renders person currently on call.
  """
  def render_on_call_person(conn) do
    people =
      case Artemis.Worker.PagerDutyOnCallSynchronizer.fetch_data() do
        nil ->
          []

        data ->
          data
          |> Enum.flat_map(fn {_, value} -> value end)
          |> Enum.filter(&(Map.get(&1, "escalation_level") == 1))
          |> Enum.map(&Artemis.Helpers.deep_get(&1, ["user", "summary"]))
          |> Enum.uniq()
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_person.html", conn: conn, people: people)
  end

  @doc """
  Renders current status as a colored dot and link to more information.
  """
  def render_on_call_status(conn) do
    totals = get_pager_duty_incident_totals()

    color =
      cond do
        has_incident_status?(totals, :triggered) -> "red"
        has_incident_status?(totals, :acknowledged) -> "yellow"
        Artemis.Helpers.present?(totals) -> "green"
        true -> "gray"
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_status.html", conn: conn, color: color)
  end

  defp has_incident_status?(totals, status) do
    case Map.get(totals, status) do
      nil -> false
      0 -> false
      _ -> true
    end
  end

  @doc """
  Render a Phoenix LiveView of PagerDuty summary
  """
  def render_pager_duty_live(conn) do
    authorized? = has?(conn, "incidents:list")
    incident_status_enabled? = Artemis.Worker.PagerDutyIncidentStatus.enabled?()
    on_call_enabled? = Artemis.Worker.PagerDutyOnCallSynchronizer.enabled?()

    if authorized? && incident_status_enabled? && on_call_enabled? do
      content_tag(:content) do
        content_tag(:section) do
          Phoenix.LiveView.live_render(conn, ArtemisWeb.PagerDutyLive)
        end
      end
    end
  end

  @doc """
  Render a summary for all PagerDuty teams
  """
  def render_pager_duty_summary(conn, updated_at) do
    incident_totals = get_pager_duty_incident_totals()

    assigns = [
      conn: conn,
      section_acknowledged: render_section_acknowledged(conn, incident_totals),
      section_triggered: render_section_triggered(conn, incident_totals),
      updated_at: updated_at
    ]

    Phoenix.View.render(ArtemisWeb.OnCallView, "index/pager_duty_summary.html", assigns)
  end

  defp get_pager_duty_incident_totals() do
    data = Artemis.Worker.PagerDutyIncidentStatus.fetch_data()

    acknowledged =
      Enum.reduce(data, [], fn {_, entry}, acc ->
        Map.get(entry, "acknowledged", []) ++ acc
      end)

    triggered =
      Enum.reduce(data, [], fn {_, entry}, acc ->
        Map.get(entry, "triggered", []) ++ acc
      end)

    %{
      acknowledged: length(acknowledged),
      triggered: length(triggered)
    }
  end

  defp render_section_acknowledged(conn, incident_totals) do
    query_params = [
      filters: [
        status: "acknowledged"
      ]
    ]

    class = if incident_totals.acknowledged > 0, do: "active"
    path = ArtemisWeb.Router.Helpers.incident_path(conn, :index, query_params)

    content_tag(:a, class: "acknowledged #{class}", href: path) do
      [
        content_tag(:span, incident_totals.acknowledged, class: "count"),
        content_tag(:span, "Acknowledged", class: "label")
      ]
    end
  end

  defp render_section_triggered(conn, incident_totals) do
    query_params = [
      filters: [
        status: "triggered"
      ]
    ]

    class = if incident_totals.triggered > 0, do: "active"
    path = ArtemisWeb.Router.Helpers.incident_path(conn, :index, query_params)

    content_tag(:a, class: "triggered #{class}", href: path) do
      [
        content_tag(:span, incident_totals.triggered, class: "count"),
        content_tag(:span, "Triggered", class: "label")
      ]
    end
  end

  @doc """
  Render a summary for a specific team
  """
  def render_pager_duty_team_summary(conn, slug) do
    team = get_pager_duty_team(slug)
    team_id = team[:id]
    incident_totals = get_pager_duty_team_incident_totals(team_id)
    on_call = get_pager_duty_team_on_call(team_id)

    assigns = [
      conn: conn,
      incident_totals: incident_totals,
      name: team[:name],
      on_call: on_call,
      section_acknowledged: render_team_section_acknowledged(conn, incident_totals, team_id),
      section_triggered: render_team_section_triggered(conn, incident_totals, team_id),
      team_id: team_id
    ]

    Phoenix.View.render(ArtemisWeb.OnCallView, "index/pager_duty_team_summary.html", assigns)
  end

  defp get_pager_duty_team(slug) do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
    |> Enum.find(fn team ->
      Keyword.get(team, :slug) == slug
    end)
  end

  defp get_pager_duty_team_incident_totals(team_id) do
    all_statuses = Artemis.Worker.PagerDutyIncidentStatus.fetch_data()
    team_status = Map.get(all_statuses, team_id)
    acknowledged = Map.get(team_status, "acknowledged", [])
    triggered = Map.get(team_status, "triggered", [])

    %{
      acknowledged: length(acknowledged),
      triggered: length(triggered)
    }
  end

  defp get_pager_duty_team_on_call(team_id) do
    Artemis.Worker.PagerDutyOnCallSynchronizer.fetch_data()
    |> Map.get(team_id)
    |> Enum.filter(&(Map.get(&1, "escalation_level") == 1))
    |> Enum.map(fn entry ->
      %{
        name: Artemis.Helpers.deep_get(entry, ["user", "summary"]),
        scope: Artemis.Helpers.deep_get(entry, ["escalation_policy", "summary"]),
        to: Artemis.Helpers.deep_get(entry, ["escalation_policy", "html_url"])
      }
    end)
    |> Enum.uniq_by(& &1.name)
  end

  defp render_team_section_acknowledged(conn, incident_totals, team_id) do
    query_params = [
      filters: [
        status: "acknowledged",
        team_id: [team_id]
      ]
    ]

    class = if incident_totals.acknowledged > 0, do: "active"
    path = ArtemisWeb.Router.Helpers.incident_path(conn, :index, query_params)

    content_tag(:a, class: "acknowledged #{class}", href: path) do
      [
        content_tag(:i, "", class: "ui icon circle tiny"),
        content_tag(:span, incident_totals.acknowledged, class: "label"),
        "Acknowledged"
      ]
    end
  end

  defp render_team_section_triggered(conn, incident_totals, team_id) do
    query_params = [
      filters: [
        status: "triggered",
        team_id: [team_id]
      ]
    ]

    class = if incident_totals.triggered > 0, do: "active"
    path = ArtemisWeb.Router.Helpers.incident_path(conn, :index, query_params)

    content_tag(:a, class: "triggered #{class}", href: path) do
      [
        content_tag(:i, "", class: "ui icon circle tiny"),
        content_tag(:span, incident_totals.triggered, class: "label"),
        "Triggered"
      ]
    end
  end
end
