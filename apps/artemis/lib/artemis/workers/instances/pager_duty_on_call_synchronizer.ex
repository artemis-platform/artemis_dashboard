defmodule Artemis.Worker.PagerDutyOnCallSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: :timer.seconds(15),
    delayed_start: :timer.seconds(5),
    name: :pager_duty_on_call_synchronizer

  alias Artemis.Drivers.PagerDuty
  alias Artemis.Worker.PagerDutyEscalationPolicySynchronizer

  # Callbacks

  @impl true
  def call(data, _config) do
    with team_ids <- Artemis.Helpers.PagerDuty.get_pager_duty_team_ids(),
         escalation_policies <- get_escalation_policies(),
         on_calls <- get_on_calls(team_ids, escalation_policies),
         {:ok, _} <- broadcast_changes(data, on_calls) do
      {:ok, on_calls}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  end

  def enabled?() do
    Artemis.Helpers.AppConfig.all_enabled?([
      [:artemis_umbrella, :actions, :cache_warmers],
      [:artemis, :actions, :pager_duty_synchronize_on_call]
    ])
  end

  # Helpers

  defp broadcast_changes(current, next) do
    with false <- is_nil(current),
         false <- current == next do
      Artemis.PagerDutyChange.broadcast(%{
        data: next,
        schema: "on-call"
      })
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
