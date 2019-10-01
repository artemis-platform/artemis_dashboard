defmodule Artemis.Worker.PagerDutyOnCallSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 15_000,
    delayed_start: 15_000,
    name: :pager_duty_on_call_synchronizer

  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser

  defmodule Data do
    defstruct [
      :meta,
      :result
    ]
  end

  @fetch_limit 99

  # Callbacks

  @impl true
  def call(data, _config) do
    with user <- GetSystemUser.call!(),
         {:ok, escalation_policies} <- synchronize_escalation_policies(data),
         {:ok, on_calls} <- synchronize_on_calls(escalation_policies),
         {:ok, _} <- broadcast_event_when_changed(data, on_calls, user) do
      data = create_data(on_calls, escalation_policies: escalation_policies)

      {:ok, data}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    error ->
      Logger.info("Error synchronizing pager duty on call: " <> inspect(error))
      {:error, "Exception raised while synchronizing pager duty on call"}
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

  defp create_data(result, meta) do
    %Data{
      meta: Enum.into(meta, %{}),
      result: result
    }
  end

  defp broadcast_event_when_changed(data, next, user) do
    with false <- is_nil(data),
         current <- Map.get(data, :on_calls),
         false <- is_nil(current),
         false <- current == next do
      Artemis.Event.broadcast(next, "on-call:updated", user)
    else
      _ -> {:ok, "No change detected"}
    end
  end

  # Helpers - Escalation Policies

  def synchronize_escalation_policies(%{meta: %{escalation_policies: current}}) when not is_nil(current), do: current

  def synchronize_escalation_policies(_) do
    with {:ok, response} <- get_pager_duty_escalation_policies(),
         200 <- response.status_code,
         {:ok, escalation_policies} <- process_escalation_polices_response(response) do
      {:ok, escalation_policies}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    error ->
      Logger.info("Error synchronizing pager duty escalation policies: " <> inspect(error))
      {:error, "Exception raised while synchronizing pager duty escalation policies"}
  end

  def get_pager_duty_escalation_policies() do
    path = "/escalation_policies"
    headers = []

    options = [
      params: [
        limit: @fetch_limit,
        offset: 0,
        "team_ids[]": get_team_ids()
      ]
    ]

    PagerDuty.get(path, headers, options)
  end

  defp process_escalation_polices_response(%HTTPoison.Response{body: %{"escalation_policies" => entries}}) do
    {:ok, Enum.map(entries, &Map.fetch!(&1, "id"))}
  rescue
    _ -> {:error, "Error processing escalation policies"}
  end

  defp process_escalation_polices_response(_), do: {:error, "Invalid escalation policies response"}

  # Helpers - On Calls

  def synchronize_on_calls(escalation_policies) do
    with {:ok, response} <- get_pager_duty_on_calls(escalation_policies),
         200 <- response.status_code,
         {:ok, on_calls} <- process_on_calls_response(response) do
      {:ok, on_calls}
    else
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    _ -> {:error, "Exception raised while synchronizing on calls"}
  end

  def get_pager_duty_on_calls(escalation_policies) do
    path = "/oncalls"
    headers = []

    additional_params =
      case is_list(escalation_policies) do
        true -> Enum.map(escalation_policies, &{"escalation_policy_ids[]", &1})
        false -> []
      end

    options = [
      params:
        [
          # "include[]": "escalation_policies",
          # "include[]": "schedules",
          # "include[]": "users",
          limit: @fetch_limit,
          offset: 0
        ] ++ additional_params
    ]

    PagerDuty.get(path, headers, options)
  end

  defp process_on_calls_response(%HTTPoison.Response{body: %{"oncalls" => entries}}) do
    {:ok, entries}
  rescue
    _ -> {:error, "Error processing on calls"}
  end

  defp process_on_calls_response(_), do: {:error, "Invalid on calls response"}

  def get_team_ids, do: Application.fetch_env!(:artemis, :pager_duty)[:team_ids]
end
