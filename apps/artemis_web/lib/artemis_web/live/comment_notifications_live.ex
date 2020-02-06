defmodule ArtemisWeb.CommentNotificationsLive do
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
      |> assign(:path, session.path)
      |> assign(:resource_id, resource_id)
      |> assign(:resource_type, resource_type)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "comment_notifications.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: event, payload: payload}, socket) do
    socket = update_if_match(socket, event, payload)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # Helpers

  defp update_if_match(socket, event, payload) do
    resource_id = Artemis.Helpers.deep_get(payload, [:data, :resource_id])
    resource_type = Artemis.Helpers.deep_get(payload, [:data, :resource_type])

    events = [
      "comment:created",
      "comment:deleted",
      "comment:updated"
    ]

    event_match? = Enum.member?(events, event)
    resource_type_match? = resource_type == socket.assigns.resource_type

    case event_match? && resource_type_match? && resource_id_match?(socket, resource_id) do
      true -> update_socket(socket, payload)
      false -> socket
    end
  end

  defp resource_id_match?(socket, resource_id) do
    case Artemis.Helpers.present?(socket.assigns.resource_id) do
      true -> Artemis.Helpers.to_string(resource_id) == socket.assigns.resource_id
      _ -> true
    end
  end

  defp update_socket(socket, payload) do
    inserted_at = Artemis.Helpers.deep_get(payload, [:data, :inserted_at])
    user_name = Artemis.Helpers.deep_get(payload, [:user, :name])

    socket
    |> assign(:event_received_at, inserted_at)
    |> assign(:event_received_by, user_name)
  end
end
