defmodule ArtemisWeb.SessionLive do
  use ArtemisWeb.LiveView

  import ArtemisWeb.Helpers.Presence

  alias ArtemisPubSub.Presence

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    ArtemisPubSub.subscribe(get_presence_topic())

    assigns = assign(socket, :presences, list_all_presences())

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.SessionView, "_live_sessions.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    assigns = assign(socket, :presences, list_all_presences())

    {:noreply, assigns}
  end
end
