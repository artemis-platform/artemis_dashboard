defmodule Artemis.Worker.PagerDutyIncidentSynchronizerInstance do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.hours(6),
    interval: :timer.hours(6),
    name: :pager_duty_incident_synchronizer

  alias Artemis.Drivers.PagerDuty

  # Callbacks

  @impl true
  def call(_data, config) do
    team_id = Keyword.get(config, :id)
    result = synchronize_incidents(team_id)

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

  defp synchronize_incidents(team_id) do
    {:ok, result} = PagerDuty.SynchronizeIncidents.call(team_id)

    length(result.data)
  end
end
