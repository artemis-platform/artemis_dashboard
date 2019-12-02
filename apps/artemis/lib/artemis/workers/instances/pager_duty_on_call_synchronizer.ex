defmodule Artemis.Worker.PagerDutyOnCallSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: :timer.seconds(15),
    delayed_start: :timer.seconds(5),
    name: :pager_duty_on_call_synchronizer

  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser
  alias Artemis.Worker.PagerDutyEscalationPolicySynchronizer

  # Callbacks

  @impl true
  def call(data, _config) do
    with team_ids <- get_team_ids(),
         escalation_policies <- get_escalation_policies(),
         on_calls <- get_on_calls(team_ids, escalation_policies),
         system_user <- GetSystemUser.call!(),
         {:ok, _} <- broadcast_event_when_changed(data, on_calls, system_user) do
      {:ok, on_calls}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:pager_duty_synchronize_on_call)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp get_team_ids() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
    |> Enum.map(&Keyword.fetch!(&1, :id))
  end

  defp broadcast_event_when_changed(current, next, user) do
    with false <- is_nil(current),
         false <- current == next do
      Artemis.Event.broadcast(next, "pager-duty:on-calls:updated", user)
    else
      _ -> {:ok, "No change detected"}
    end
  end

  # Helpers - Escalation Policies

  defp get_escalation_policies(), do: PagerDutyEscalationPolicySynchronizer.fetch_data()

  # Helpers - On Calls

  defp get_on_calls(team_ids, escalation_policies) do
    Enum.reduce(team_ids, %{}, fn team_id, acc ->
      team_escalation_policies = Map.get(escalation_policies, team_id, [])
      on_calls = get_on_calls_by_escalation_policies(team_escalation_policies)

      Map.put(acc, team_id, on_calls)
    end)
  end

  defp get_on_calls_by_escalation_policies(team_escalation_policies) when length(team_escalation_policies) == 0 do
    {:ok, []}
  end

  defp get_on_calls_by_escalation_policies(team_escalation_policies) do
    request_params = Enum.map(team_escalation_policies, &{:"escalation_policy_ids[]", &1})

    options = [
      request_params: request_params
    ]

    {:ok, result} = PagerDuty.ListOnCalls.call(options)

    result.data
  end
end
