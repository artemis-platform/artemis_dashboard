defmodule ArtemisWeb.PresenceLive do
  use ArtemisWeb.LiveView

  import ArtemisWeb.Helpers.Presence

  alias ArtemisPubSub.Presence

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    user = session.current_user
    path = session.request_path
    id = "user:#{user.id}:path:#{path}"
    topic = get_presence_topic()
    payload = get_presence_payload(path, user)

    Presence.track(self(), topic, id, payload)

    ArtemisPubSub.subscribe(topic)

    assigns =
      socket
      |> assign(:current_path, filter_presences_by(:path, path))
      |> assign(:path, path)
      |> assign(:total, total_unique_presences())
      |> assign(:user, user)

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "presence.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    assigns =
      socket
      |> assign(:current_path, filter_presences_by(:path, socket.assigns.path))
      |> assign(:total, total_unique_presences())

    {:noreply, assigns}
  end
end
