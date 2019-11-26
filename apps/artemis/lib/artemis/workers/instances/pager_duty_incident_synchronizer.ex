defmodule Artemis.Worker.PagerDutyIncidentSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.hours(6),
    interval: :timer.hours(6),
    name: :pager_duty_incident_synchronizer

  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser

  defmodule Data do
    defstruct [
      :meta,
      :result
    ]
  end

  # Callbacks

  @impl true
  def call(_data, _config) do
    system_user = GetSystemUser.call!()
    team_ids = get_team_ids()
    result = synchronize_incidents(team_ids, system_user)

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

  defp synchronize_incidents(team_ids, user) do
    Enum.reduce(team_ids, %{}, fn team_id, acc ->
      {:ok, result} = PagerDuty.SynchronizeIncidents.call(team_id, user)

      total = length(result.data)

      Map.put(acc, team_id, total)
    end)
  end

  defp get_team_ids do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
    |> Enum.map(&Keyword.fetch!(&1, :id))
  end
end
