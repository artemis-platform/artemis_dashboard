defmodule ArtemisWeb.AsyncRenderLive do
  use ArtemisWeb.LiveView

  @moduledoc """
  Asynchronously render a template

  ## Fetch Data Asynchronously (Optional)

  Can be passed an arbitrary `async_data` function to be executed as part of
  the async load. It is excluded from the assign data and never exposed to the
  client.

  Supports multiple formats:

  - Tuple: `{Module, :function_name}`
  - Named Function: `&custom_function/1`
  - Anyonmous Function: `fn _assigns -> true end`

  Note: In order to pass a named or anonymous function, it must first be
  serialized with the exposed `serialize` function first.
  """

  @async_data_timeout :timer.minutes(5)
  @ignored_session_keys ["async_data", "conn"]
  @default_async_render_type :component

  # LiveView Callbacks

  @impl true
  def mount(_params, session, socket) do
    async_fetch? = Map.get(session, "async_fetch?", true)
    async_render_reload_limit = session["async_data_reload_limit"]
    async_render_type = session["async_render_type"] || @default_async_render_type
    async_status_after_initial_render = session["async_status_after_initial_render"] || :loading

    private_state = [
      async_data: session["async_data"]
    ]

    {:ok, async_render_private_state_pid} = ArtemisWeb.AsyncRenderLivePrivateState.start_link(private_state)

    socket =
      socket
      |> add_session_to_assigns(session)
      |> assign(:async_data, nil)
      |> assign(:async_data_reload_count, 0)
      |> assign(:async_data_reload_limit, async_render_reload_limit)
      |> assign(:async_fetch?, async_fetch?)
      |> assign(:async_render_private_state_pid, async_render_private_state_pid)
      |> assign(:async_render_type, async_render_type)
      |> assign(:async_status, :loading)
      |> assign(:async_status_after_initial_render, async_status_after_initial_render)
      |> maybe_fetch_data()

    if connected?(socket) && async_fetch? do
      Process.send_after(self(), :async_data, 10)
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "async_render.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(:async_data, socket) do
    {:noreply, add_async_data(socket)}
  end

  def handle_info(:context_cache_updating, socket) do
    socket = assign(socket, :async_data_reload_count, socket.assigns.async_data_reload_count + 1)

    socket =
      case below_reload_limit?(socket) do
        true -> assign(socket, :async_status, :reloading)
        false -> socket
      end

    {:noreply, socket}
  end

  def handle_info(:context_cache_updated, socket) do
    if below_reload_limit?(socket) do
      Process.send(self(), :async_data, [])
    end

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Callbacks

  def deserialize(binary) do
    :erlang.binary_to_term(binary)
  rescue
    _error in ArgumentError -> binary
  end

  def serialize(term), do: :erlang.term_to_binary(term)

  # Helpers

  defp add_session_to_assigns(socket, session) do
    Enum.reduce(session, socket, fn {key, value}, acc ->
      atom_key = Artemis.Helpers.to_atom(key)

      case Enum.member?(@ignored_session_keys, key) do
        false -> assign(acc, atom_key, value)
        true -> acc
      end
    end)
  end

  defp maybe_fetch_data(socket) do
    case socket.assigns.async_fetch? do
      true -> socket
      _ -> add_async_data(socket, async_status: socket.assigns.async_status_after_initial_render)
    end
  end

  defp add_async_data(socket, options \\ []) do
    async_data = fetch_async_data(socket)
    async_status = Keyword.get(options, :async_status, :loaded)

    socket
    |> assign(:async_data, async_data)
    |> assign(:async_status, async_status)
  end

  defp fetch_async_data(socket) do
    pid = socket.assigns.async_render_private_state_pid
    message = {:async_data, self(), socket.assigns}

    GenServer.call(pid, message, @async_data_timeout)
  end

  defp below_reload_limit?(socket) do
    reload_count = socket.assigns.async_data_reload_count
    reload_limit = socket.assigns.async_data_reload_limit

    cond do
      reload_limit -> reload_count <= reload_limit
      true -> true
    end
  end
end
