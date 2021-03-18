defmodule Artemis.Worker.PagerDutyIncidentStatus do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.seconds(10),
    interval: :timer.minutes(1),
    name: :pager_duty_incident_status

  require Logger

  alias Artemis.Drivers.PagerDuty

  # Callbacks

  @impl true
  def call(data, _config) do
    team_ids = Artemis.Helpers.PagerDuty.get_pager_duty_team_ids()

    statuses = [
      "acknowledged",
      "triggered"
    ]

    result = get_incident_status_summary(team_ids, statuses)

    broadcast_changes(data, result)

    {:ok, result}
  end

  def enabled?() do
    Artemis.Helpers.AppConfig.enabled?(:artemis, :actions, :pager_duty_synchronize_incidents)
  end

  # Helpers

  defp get_incident_status_summary(team_ids, statuses) do
    Enum.reduce(team_ids, %{}, fn team_id, acc ->
      by_status = get_incidents_by_statuses(team_id, statuses)

      Map.put(acc, team_id, by_status)
    end)
  end

  defp get_incidents_by_statuses(team_id, statuses) do
    Enum.reduce(statuses, %{}, fn status, acc ->
      incident_ids = get_incidents_by_status(team_id, status)

      Map.put(acc, status, incident_ids)
    end)
  end

  defp get_incidents_by_status(team_id, status) do
    request_params = [
      "statuses[]": status,
      "team_ids[]": team_id
    ]

    options = [
      request_params: request_params
    ]

    incidents =
      case PagerDuty.ListIncidents.call(options) do
        {:ok, result} ->
          result.data

        error ->
          Logger.info("Error in PagerDuty incident status " <> inspect(error))
          []
      end

    Enum.map(incidents, fn incident ->
      %{
        acknowledged_at: incident.acknowledged_at,
        source_uid: incident.source_uid,
        triggered_at: incident.triggered_at
      }
    end)
  end

  defp broadcast_changes(current_data, next_data) do
    Enum.map(Artemis.Helpers.PagerDuty.get_pager_duty_team_ids(), fn team_id ->
      current_team_data = Map.get(current_data || %{}, team_id)
      next_team_data = Map.get(next_data, team_id)
      changed? = current_team_data != next_team_data

      if changed? do
        Artemis.PagerDutyChange.broadcast(%{
          data: next_team_data,
          schema: "incident",
          team_id: team_id
        })
      end
    end)
  end
end
