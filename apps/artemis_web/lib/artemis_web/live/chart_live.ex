defmodule ArtemisWeb.ChartLive do
  use ArtemisWeb.LiveView

  @moduledoc """
  LiveView GenServer for managing a JavaScript chart instance.

  Fetches the initial data and listens for refetch events, updating the chart
  when new data is available.
  """

  @refresh_rate 1_000

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    socket =
      socket
      |> assign(:chart_data, nil)
      |> assign(:chart_id, session.chart_id)
      |> assign(:chart_options, session.chart_options)
      |> assign(:fetch_data_on_cloudant_changes, session.fetch_data_on_cloudant_changes)
      |> assign(:fetch_data_on_events, session.fetch_data_on_events)
      |> assign(:fetch_data_timer, nil)
      |> assign(:module, session.module)
      |> assign(:user, session.user)

    socket = get_data_at_mount(session, socket)

    subscribe_to_cloudant_changes(socket.assigns)
    subscribe_to_events(socket.assigns)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "chart_live.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: _, payload: payload}, socket) do
    socket = parse_cloudant_change(payload, socket)

    {:noreply, socket}
  end

  def handle_info(%{event: event}, socket) do
    socket = parse_event(event, socket)

    {:noreply, socket}
  end

  def handle_info(:fetch_data, socket) do
    module = Map.get(socket.assigns, :module)
    user = Map.get(socket.assigns, :user)
    chart_data = fetch_data(module, user)

    socket =
      socket
      |> assign(:chart_data, chart_data)
      |> assign(:fetch_data_timer, nil)

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Helpers

  defp get_data_at_mount(session, socket) do
    case session.fetch_data_async do
      true ->
        fetch_data_debounce(socket, 10)

      _ ->
        chart_data = fetch_data(session.module, session.user)
        chart_options = Map.merge(session.chart_options, chart_data)

        socket
        |> assign(:chart_data, chart_data)
        |> assign(:chart_options, chart_options)
    end
  end

  defp subscribe_to_cloudant_changes(%{fetch_data_on_cloudant_changes: changes}) when length(changes) > 0 do
    Enum.map(changes, fn change ->
      schema = Map.get(change, :schema)
      topic = Artemis.CloudantChange.topic(schema)

      :ok = ArtemisPubSub.subscribe(topic)
    end)
  end

  defp subscribe_to_cloudant_changes(_), do: :skipped

  defp subscribe_to_events(%{fetch_data_on_events: events}) when length(events) > 0 do
    topic = Artemis.Event.get_broadcast_topic()

    :ok = ArtemisPubSub.subscribe(topic)
  end

  defp subscribe_to_events(_state), do: :skipped

  defp parse_cloudant_change(payload, socket) do
    case matches_any?(socket.assigns.fetch_data_on_cloudant_changes, payload) do
      true -> fetch_data_debounce(socket)
      false -> socket
    end
  end

  defp parse_event(event, socket) do
    case Enum.member?(socket.assigns.fetch_data_on_events, event) do
      true -> fetch_data_debounce(socket)
      false -> socket
    end
  end

  defp matches_any?(items, target) do
    Enum.any?(items, &Artemis.Helpers.subset?(&1, target))
  end

  defp fetch_data_debounce(socket, delay \\ @refresh_rate) do
    case socket.assigns.fetch_data_timer do
      nil -> assign(socket, :fetch_data_timer, Process.send_after(self(), :fetch_data, delay))
      _ -> socket
    end
  end

  defp fetch_data(module, user), do: module.fetch_data(user)
end
