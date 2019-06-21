defmodule ArtemisWeb.SharedJobLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    assigns = assign(socket, :job, session.job)

    :ok = ArtemisPubSub.subscribe(Artemis.CloudantChange.topic())

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.SharedJobView, "_record.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "cloudant-change", payload: payload}, socket) do
    socket = update_if_match(socket, payload)

    {:noreply, socket}
  end

  # Helpers

  defp update_if_match(socket, %{action: action, document: document, id: id}) do
    match? = (id == socket.assigns.job._id)

    cond do
      match? && action == "delete" -> assign(socket, :job, document)
      match? && action == "create" -> assign(socket, :job, document)
      match? && action == "update" -> assign(socket, :job, document)
      true -> socket
    end
  end
end
