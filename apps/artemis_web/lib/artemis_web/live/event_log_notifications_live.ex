defmodule ArtemisWeb.EventLogNotificationsLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    resource_id = Artemis.Helpers.to_string(session.resource_id)
    resource_type = Artemis.Helpers.to_string(session.resource_type)
    broadcast_topic = Artemis.Event.get_broadcast_topic()
    timestamp = DateTime.utc_now()

    socket =
      socket
      |> assign(:connected_at, timestamp)
      |> assign(:current_user, session.current_user)
      |> assign(:event_received_at, nil)
      |> assign(:event_received_by, nil)
      |> assign(:resource_id, resource_id)
      |> assign(:resource_type, resource_type)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.EventLogView, "_notifications.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "event-log:created", payload: %{data: data}}, socket) do
    socket = update_if_match(socket, data)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # Helpers

  defp update_if_match(socket, %{resource_id: resource_id, resource_type: resource_type} = data) do
    resource_type_match? = Artemis.Helpers.to_string(resource_type) == socket.assigns.resource_type
    resource_id_match? = Artemis.Helpers.to_string(resource_id) == socket.assigns.resource_id

    case resource_type_match? && resource_id_match? do
      true -> update_socket(socket, data)
      false -> socket
    end
  end

  defp update_socket(socket, data) do
    socket
    |> assign(:event_received_at, Map.get(data, :inserted_at))
    |> assign(:event_received_by, Map.get(data, :user_name))
  end
end
