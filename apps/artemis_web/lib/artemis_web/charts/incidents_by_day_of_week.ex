defmodule ArtemisWeb.Charts.IncidentsByDayOfWeek do
  use ArtemisWeb.Charts

  @cloudant_changes []

  @events [
    "incident:created",
    "incident:deleted",
    "incident:updated"
  ]

  @days_of_week %{
    1.0 => :Mon,
    2.0 => :Tue,
    3.0 => :Wed,
    4.0 => :Thu,
    5.0 => :Fri,
    6.0 => :Sat,
    7.0 => :Sun
  }

  def render(conn, options \\ []) do
    user = current_user(conn)
    chart_data = fetch_data(options, user)

    chart_options =
      options
      |> get_chart_options()
      |> Map.merge(chart_data)

    assigns = [
      chart_data: chart_data,
      chart_id: Artemis.Helpers.UUID.call(),
      chart_options: chart_options,
      chart_type: "bar",
      conn: conn,
      fetch_data_on_cloudant_changes: @cloudant_changes,
      fetch_data_on_events: @events,
      module: __MODULE__,
      user: user
    ]

    Phoenix.View.render(ArtemisWeb.LayoutView, "chart.html", assigns)
  end

  def fetch_data(options, user) do
    totals =
      options
      |> get_chart_data(user)
      |> total_chart_data()
      |> Enum.reverse()

    %{
      series: totals,
      xaxis: %{
        categories: Map.values(@days_of_week)
      }
    }
  end

  # Helpers

  defp get_chart_options(options) do
    default_options = ArtemisWeb.ViewHelper.Charts.get_chart_type_options(:bar)
    custom_options = get_custom_chart_options(options)

    Artemis.Helpers.deep_merge(default_options, custom_options)
  end

  defp get_custom_chart_options(options) do
    stroke_background = if options[:theme] == :dark, do: "#222529", else: "#fff"

    %{
      chart: %{
        stacked: true
      },
      dataLabels: %{
        enabled: false
      },
      legend: %{
        position: "right"
      },
      stroke: %{
        colors: [stroke_background]
      },
      xaxis: %{
        labels: %{
          style: %{
            fontSize: "14px"
          }
        }
      }
    }
  end

  defp get_chart_data(options, user) do
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

  defp total_chart_data(rows) do
    team_ids = Artemis.Helpers.PagerDuty.get_pager_duty_team_ids()

    Enum.reduce(team_ids, [], fn team_id, acc ->
      data =
        Enum.map(@days_of_week, fn {day_index, _day_name} ->
          Enum.find_value(rows, fn [team_id_to_match, _service_name, index_to_match, count] ->
            team_id_to_match == team_id && index_to_match == day_index && count
          end) || 0
        end)

      entry = %{
        name: Artemis.Helpers.PagerDuty.get_pager_duty_team_name(team_id),
        data: data
      }

      [entry | acc]
    end)
  end
end
