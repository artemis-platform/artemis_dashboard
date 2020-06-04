defmodule ArtemisWeb.CommentCountLabelLive do
  use ArtemisWeb.LiveView

  alias Artemis.ListComments

  # LiveView Callbacks

  @impl true
  def mount(_params, session, socket) do
    resource_id = Artemis.Helpers.to_string(session["resource_id"])
    resource_type = Artemis.Helpers.to_string(session["resource_type"])
    broadcast_topic = Artemis.CacheEvent.get_broadcast_topic()

    assigns =
      socket
      |> assign(:count, nil)
      |> assign(:resource_id, resource_id)
      |> assign(:resource_type, resource_type)
      |> assign(:status, :loading)
      |> assign(:user, session["user"])

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

  def handle_info(%{event: "cache:reset", payload: payload}, socket) do
    update_if_match(socket, payload)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # Helpers

  defp update_if_match(socket, payload) do
    if module_match?(payload) && resource_id_match?(socket, payload) do
      Process.send(self(), {:update_data, :updated}, [])
    end
  end

  defp module_match?(%{module: Artemis.ListComments}), do: true
  defp module_match?(_payload), do: false

  defp resource_id_match?(socket, payload) do
    case Artemis.Helpers.present?(socket.assigns.resource_id) do
      true -> socket.assigns.resource_id == get_resource_id(payload)
      _ -> true
    end
  end

  defp get_resource_id(payload) do
    payload
    |> Artemis.Helpers.deep_get([:meta, :data, :resource_id])
    |> Artemis.Helpers.to_string()
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
