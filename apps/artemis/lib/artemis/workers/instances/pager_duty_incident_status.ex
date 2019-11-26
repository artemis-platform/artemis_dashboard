defmodule Artemis.Worker.PagerDutyIncidentStatus do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.seconds(30),
    interval: :timer.seconds(30),
    name: :pager_duty_incident_status

  alias Artemis.Drivers.PagerDuty

  defmodule Data do
    defstruct [
      :meta,
      :result
    ]
  end

  # Callbacks

  @impl true
  def call(_data, _config) do
    team_ids = get_team_ids()

    statuses = [
      "acknowledged",
      "triggered"
    ]

    result = get_incident_status_summary(team_ids, statuses)

    %Data{result: result}
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:pager_duty_synchronize_incidents)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

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

    {:ok, result} = PagerDuty.ListIncidents.call(options)

    Enum.map(result.data, fn incident ->
      %{
        acknowledged_at: incident.acknowledged_at,
        source_uid: incident.source_uid,
        triggered_at: incident.triggered_at
      }
    end)
  end

  defp get_team_ids do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
    |> Enum.map(&Keyword.fetch!(&1, :id))
  end
end
