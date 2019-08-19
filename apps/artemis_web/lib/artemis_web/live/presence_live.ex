defmodule ArtemisWeb.PresenceLive do
  use ArtemisWeb.LiveView

  alias ArtemisPubSub.Presence

  def get_topic(path), do: "artemis-web:presence:#{path}"

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    user = session.current_user
    path = session.request_path
    topic = get_topic(path)
    payload = get_presence_payload(user)

    Presence.track(self(), topic, user.id, payload)

    ArtemisPubSub.subscribe(topic)

    assigns = 
      socket
      |> assign(:path, path)
      |> assign(:topic, topic)
      |> assign(:user, user)
      |> assign(:users, list_presences(topic))

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "presence.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    topic = Map.get(socket.assigns, :topic)
    assigns = assign(socket, :users, list_presences(topic))

    {:noreply, assigns}
  end

  # Helpers

  defp get_presence_payload(user) do
    %{
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name
    }
  end

  def list_presences(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {_user_id, data} ->
      List.first(data[:metas])
    end)
  end

  # def update_presence(pid, topic, key, payload) do
  #   metas =
  #     topic
  #     |> ArtemisWeb.Presence.get_by_key(key)
  #     |> Keyword.get(:metas)
  #     |> List.first()
  #     |> Map.merge(payload)

  #   ArtemisWeb.Presence.update(pid, topic, key, metas)
  # end
end
