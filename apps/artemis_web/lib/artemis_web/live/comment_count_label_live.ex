defmodule ArtemisWeb.CommentCountLabelLive do
  use ArtemisWeb.LiveView

  alias Artemis.ListComments

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    assigns =
      socket
      |> assign(:count, nil)
      |> assign(:resource_id, session.resource_id)
      |> assign(:resource_type, session.resource_type)
      |> assign(:status, :loading)
      |> assign(:user, session.user)

    if connected?(socket), do: Process.send_after(self(), {:update_data, :loaded}, 10)

    :ok = ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "secondary_navigation_comment_count_label.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: event, payload: payload}, socket) do
    update_if_match(socket, event, payload)

    {:noreply, socket}
  end

  def handle_info({:update_data, status}, socket) do
    socket = update_data(socket, status)

    {:noreply, socket}
  end

  # Helpers

  defp update_if_match(socket, event, payload) do
    resource_id = Artemis.Helpers.deep_get(payload, [:data, :resource_id])
    resource_type = Artemis.Helpers.deep_get(payload, [:data, :resource_type])

    resource_id_match? = resource_id == Integer.to_string(socket.assigns.resource_id)
    resource_type_match? = resource_type == socket.assigns.resource_type
    resource_match? = resource_id_match? && resource_type_match?

    events = [
      "comment:created",
      "comment:deleted",
      "comment:updated"
    ]

    event_match? = Enum.member?(events, event)

    if resource_match? && event_match? do
      Process.send_after(self(), {:update_data, :updated}, 150)
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
