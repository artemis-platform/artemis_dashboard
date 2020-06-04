defmodule ArtemisWeb.PagerDutyLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :updated_at, Timex.now())

    subscribe_to_incident_changes()
    subscribe_to_on_call_changes()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ArtemisWeb.ViewHelper.OnCall.render_pager_duty_summary(assigns[:socket], assigns[:updated_at])
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{payload: _payload}, socket) do
    socket = assign(socket, :updated_at, Timex.now())

    {:noreply, socket}
  end

  # Helpers

  defp subscribe_to_incident_changes() do
    schema = "incident"
    topic = Artemis.PagerDutyChange.get_topic(schema)

    :ok = ArtemisPubSub.subscribe(topic)
  end

  defp subscribe_to_on_call_changes() do
    schema = "on-call"
    topic = Artemis.PagerDutyChange.get_topic(schema)

    :ok = ArtemisPubSub.subscribe(topic)
  end
end
