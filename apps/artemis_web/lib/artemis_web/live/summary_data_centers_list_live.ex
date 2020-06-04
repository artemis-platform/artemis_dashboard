defmodule ArtemisWeb.SummaryDataCentersListLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(_params, session, socket) do
    broadcast_topic = Artemis.CacheEvent.get_broadcast_topic()

    assigns =
      socket
      |> assign(:data, [])
      |> assign(:status, :loading)
      |> assign(:user, session["user"])

    socket = update_data(assigns, :loaded)

    :ok = ArtemisPubSub.subscribe(broadcast_topic)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "summary_data_centers_list.html", assigns)
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
      paginate: false,
      preload: [:clouds, :customers, :machines]
    }

    params
    |> Artemis.ListDataCenters.call_with_cache(socket.assigns.user)
    |> Map.get(:data)
    |> Enum.map(fn entry ->
      entry
      |> Map.from_struct()
      |> Map.put(:cloud_count, length(entry.clouds))
      |> Map.put(:customer_count, length(entry.customers))
      |> Map.put(:machine_count, length(entry.machines))
      |> Map.delete(:clouds)
      |> Map.delete(:customers)
      |> Map.delete(:machines)
      |> Map.delete(:__meta__)
    end)
  end
end
