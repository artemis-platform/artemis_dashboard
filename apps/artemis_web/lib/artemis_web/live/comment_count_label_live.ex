defmodule ArtemisWeb.CommentCountLabelLive do
  use ArtemisWeb.LiveView

  alias Artemis.ListComments

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    resource_id = Artemis.Helpers.to_string(session.resource_id)
    resource_type = Artemis.Helpers.to_string(session.resource_type)
    broadcast_topic = Artemis.Event.get_broadcast_topic()

    assigns =
      socket
      |> assign(:count, nil)
      |> assign(:resource_id, resource_id)
      |> assign(:resource_type, resource_type)
      |> assign(:status, :loading)
      |> assign(:user, session.user)

    if connected?(socket), do: Process.send_after(self(), {:update_data, :loaded}, 10)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "secondary_navigation_comment_count_label.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info({:update_data, status}, socket) do
    socket = update_data(socket, status)

    {:noreply, socket}
  end

  def handle_info(%{event: event, payload: %{data: data}}, socket) do
    update_if_match(socket, event, data)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # Helpers

  defp update_if_match(socket, event, %{resource_id: resource_id, resource_type: resource_type}) do
    events = [
      "comment:created",
      "comment:deleted",
      "comment:updated"
    ]

    event_match? = Enum.member?(events, event)
    resource_type_match? = resource_type == socket.assigns.resource_type

    if event_match? && resource_type_match? && resource_id_match?(socket, resource_id) do
      Process.send_after(self(), {:update_data, :updated}, 150)
    end
  end

  defp resource_id_match?(socket, resource_id) do
    case Artemis.Helpers.present?(socket.assigns.resource_id) do
      true -> Artemis.Helpers.to_string(resource_id) == socket.assigns.resource_id
      _ -> true
    end
  end

  defp update_data(socket, status) do
    count = get_count(socket)

    socket
    |> assign(:count, count)
    |> assign(:status, status)
  end

  defp get_count(socket) do
    filters = %{
      resource_id: socket.assigns.resource_id,
      resource_type: socket.assigns.resource_type
    }

    params = %{
      count: true,
      filters: filters,
      paginate: false
    }

    params
    |> ListComments.call_with_cache(socket.assigns.user)
    |> Map.get(:data)
    |> hd()
    |> Map.get(:count)
  end
end
