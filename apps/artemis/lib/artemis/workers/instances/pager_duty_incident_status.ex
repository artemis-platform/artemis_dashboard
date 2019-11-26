defmodule Artemis.Worker.PagerDutyIncidentStatus do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.seconds(30),
    interval: :timer.seconds(30),
    name: :pager_duty_incident_status

  alias Artemis.Drivers.PagerDuty

  # Callbacks

  @impl true
  def call(data, _config) do
    team_ids = get_team_ids()

    statuses = [
      "acknowledged",
      "triggered"
    ]

    result = get_incident_status_summary(team_ids, statuses)

    trigger_synchronization_on_change(data, result)

    {:ok, result}
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

  defp get_team_ids do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
    |> Enum.map(&Keyword.fetch!(&1, :id))
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

  defp trigger_synchronization_on_change(current_data, next_data) do
    data_present? = current_data && current_data != %{}

    if data_present? do
      Enum.map(get_teams(), fn team ->
        current_team_data = Map.get(current_data, team)
        next_team_data = Map.get(next_data, team)
        changed? = (current_team_data != next_team_data)

        if changed? do
          call_incident_synchronizer(team)
        end
      end)
    end
  end

  defp get_teams() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
  end

  defp call_incident_synchronizer(team) do
    slug = Keyword.get(team, :slug)
    short_name = Artemis.Helpers.modulecase(slug)
    instance = String.to_atom("Elixir.Artemis.Worker.PagerDutyIncidentSynchronizerInstance.#{short_name}")
    options = [async: true]

    Artemis.Worker.PagerDutyIncidentSynchronizerInstance.update(options, instance)
  end
end
