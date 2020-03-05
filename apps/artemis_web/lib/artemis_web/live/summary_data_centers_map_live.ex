defmodule ArtemisWeb.SummaryDataCentersMapLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    broadcast_topic = Artemis.CacheEvent.get_broadcast_topic()

    assigns =
      socket
      |> assign(:data, [])
      |> assign(:id, session.id)
      |> assign(:status, :loading)
      |> assign(:user, session.user)

    if connected?(socket), do: Process.send_after(self(), {:update_data, :loaded}, 10)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "summary_data_centers_map_data.html", assigns)
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

  defp module_match?(_socket, %{module: module}) do
    module == Artemis.ListDataCenters
  end

  defp update_data(socket, status) do
    data = get_data(socket)

    socket
    |> assign(:data, data)
    |> assign(:status, status)
  end

  defp get_data(socket) do
    params = %{
      paginate: false
    }

    params
    |> Artemis.ListDataCenters.call_with_cache(socket.assigns.user)
    |> Map.get(:data)
    |> Enum.map(fn record ->
      %{}
      |> Map.put(:title, record.name)
      |> Map.put(:latitude, record.latitude && String.to_float(record.latitude))
      |> Map.put(:longitude, record.longitude && String.to_float(record.longitude))
      |> Map.put(:url, ArtemisWeb.Router.Helpers.data_center_path(socket, :show, record.id))
      |> Map.put(:color, Enum.random(["#e14eca"]))
    end)
  end
end
