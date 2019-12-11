defmodule Artemis.Worker.PagerDutyEscalationPolicySynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: :timer.hours(1),
    delayed_start: :timer.hours(1),
    name: :pager_duty_escalation_policy_synchronizer

  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser

  # Callbacks

  @impl true
  def call(data, _config) do
    with team_ids <- Artemis.Helpers.PagerDuty.get_pager_duty_team_ids(),
         escalation_policies <- get_escalation_policies(team_ids),
         system_user <- GetSystemUser.call!(),
         {:ok, _} <- broadcast_event_when_changed(data, escalation_policies, system_user) do
      {:ok, escalation_policies}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:pager_duty_synchronize_escalation_policies)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp broadcast_event_when_changed(current, next, user) do
    with false <- is_nil(current),
         false <- current == next do
      Artemis.Event.broadcast(next, "pager-duty:escalation-policies:updated", user)
    else
      _ -> {:ok, "No change detected"}
    end
  end

  # Helpers - Escalation Policies

  defp get_escalation_policies(team_ids) do
    Enum.reduce(team_ids, %{}, fn team_id, acc ->
      escalation_policies = get_escalation_policies_by_team(team_id)
      escalation_policy_ids = Enum.map(escalation_policies, &Map.fetch!(&1, "id"))

      Map.put(acc, team_id, escalation_policy_ids)
    end)
  end

  defp get_escalation_policies_by_team(team_id) do
    request_params = [
      "team_ids[]": team_id
    ]

    options = [
      request_params: request_params
    ]

    {:ok, result} = PagerDuty.ListEscalationPolicies.call(options)

    result.data
  end
end
