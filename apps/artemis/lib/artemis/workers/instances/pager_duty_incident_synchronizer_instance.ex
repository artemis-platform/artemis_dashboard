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

  @impl true
  def init_callback(state) do
    schema = "incident"
    topic = Artemis.PagerDutyChange.get_topic(schema)

    :ok = ArtemisPubSub.subscribe(topic)

    {:ok, state}
  end

  @impl true
  def handle_info_callback(message, state) do
    update_on_match(message, state)

    {:noreply, state}
  end

  # Helpers

  defp enabled?() do
    Artemis.Helpers.AppConfig.all_enabled?([
      [:artemis, :umbrella, :background_workers],
      [:artemis, :actions, :pager_duty_synchronize_incidents]
    ])
  end

  defp synchronize_incidents(team_id) do
    {:ok, result} = PagerDuty.SynchronizeIncidents.call(team_id)

    length(result.data)
  end

  defp update_on_match(message, state) do
    message_team_id = Artemis.Helpers.deep_get(message, [:payload, :team_id])

    instance_team_id =
      state
      |> Map.get(:config)
      |> Keyword.get(:id)

    if instance_team_id == message_team_id do
      Process.send(self(), :update, [])
    end
  end
end
