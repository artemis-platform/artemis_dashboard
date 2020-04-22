defmodule ArtemisWeb.SummaryCountLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    broadcast_topic = Artemis.CacheEvent.get_broadcast_topic()

    assigns =
      socket
      |> assign(:count, nil)
      |> assign(:label_plural, session.label_plural)
      |> assign(:label_singular, session.label_singular)
      |> assign(:module, session.module)
      |> assign(:path, session.path)
      |> assign(:status, :loading)
      |> assign(:user, session.user)

    socket = update_data(assigns, :loaded)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "summary_count.html", assigns)
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
    if module_match?(socket, payload) do
      Process.send(self(), {:update_data, :updated}, [])
    end
  end

  defp module_match?(socket, %{module: module}) do
    module == socket.assigns.module
  end

  defp update_data(socket, status) do
    count = get_count(socket)

    socket
    |> assign(:count, count)
    |> assign(:status, status)
  end

  defp get_count(socket) do
    params = %{
      count: true,
      paginate: false
    }

    params
    |> socket.assigns.module.call_with_cache(socket.assigns.user)
    |> Map.get(:data)
    |> hd()
    |> Map.get(:count)
  end
end
