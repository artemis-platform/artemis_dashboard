defmodule ArtemisWeb.ViewHelper.OnCall do
  use Phoenix.HTML

  import ArtemisWeb.UserAccess

  @doc """
  Renders person currently on call.
  """
  def render_on_call_person(conn) do
    if Artemis.Worker.PagerDutyOnCallSynchronizer.enabled?() do
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
  end

  @doc """
  Renders current status as a colored dot and link to more information.
  """
  def render_on_call_status(conn) do
    if Artemis.Worker.PagerDutyIncidentStatus.enabled?() do
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
      content_tag(:section) do
        Phoenix.LiveView.live_render(conn, ArtemisWeb.PagerDutyLive)
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
    team = Artemis.Helpers.PagerDuty.get_pager_duty_team_by_slug(slug)
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

  @doc """
  Render a summary for all ServiceNow teams
  """
  def render_service_now_summary(conn) do
    assigns = [
      conn: conn,
      web_url: get_service_now_web_url()
    ]

    Phoenix.View.render(ArtemisWeb.OnCallView, "index/service_now_summary.html", assigns)
  end

  defp get_service_now_web_url() do
    :artemis
    |> Application.fetch_env!(:service_now)
    |> Keyword.fetch!(:web_url)
  end

  @doc """
  Render PagerDuty weekly incident summary
  """
  def render_pager_duty_weekly_summary(_conn, options \\ []) do
    totals =
      options
      |> get_pager_duty_weekly_summary_data()
      |> total_pager_duty_weekly_summary_data()

    Enum.map(totals, fn {team_id, service_data} ->
      team_name = Artemis.Helpers.PagerDuty.get_pager_duty_team_name(team_id)

      service_tags =
        service_data
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn {service_name, daily_incident_count} ->
          content_tag(:div, class: "service-summary") do
            [
              content_tag(:div, service_name, class: "service-name"),
              content_tag(:div, daily_incident_count, class: "incident-total")
            ]
          end
        end)

      content_tag(:div) do
        [
          content_tag(:h5, team_name),
          service_tags
        ]
      end
    end)
  end

  defp get_pager_duty_weekly_summary_data(options) do
    user = Artemis.GetSystemUser.call!()

    reports = [
      :count_by_team_id_and_service_name_and_day_of_week
    ]

    params =
      options
      |> Enum.into(%{})
      |> Map.take([:end_date, :start_date])

    response = Artemis.ListIncidentReports.call_with_cache(reports, params, user)
    key = [:data, :count_by_team_id_and_service_name_and_day_of_week]

    Artemis.Helpers.deep_get(response, key) || []
  end

  defp total_pager_duty_weekly_summary_data(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      team_id = Enum.at(row, 0)
      service_name = Enum.at(row, 1)
      daily_incident_count = Enum.at(row, 3) || 0

      team_data =
        acc
        |> Map.get(team_id, %{})
        |> Map.update(service_name, daily_incident_count, &(&1 + daily_incident_count))

      Map.put(acc, team_id, team_data)
    end)
  end
end
