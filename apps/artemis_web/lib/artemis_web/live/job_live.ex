defmodule ArtemisWeb.JobLive do
  use ArtemisWeb.LiveView

  # LiveView Callbacks

  @impl true
  def mount(session, socket) do
    assigns =
      socket
      |> assign(:job, session.job)
      |> assign(:now, Timex.now())

    :ok = ArtemisPubSub.subscribe(Artemis.CloudantChange.topic())

    schedule_update()

    {:ok, assigns}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(ArtemisWeb.JobView, "_record.html", assigns)
  end

  # GenServer Callbacks

  @impl true
  def handle_info(%{event: "cloudant-change", payload: payload}, socket) do
    socket = update_if_match(socket, payload)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket = assign(socket, :now, Timex.now())

    schedule_update()

    {:noreply, socket}
  end

  # Helpers

  defp update_if_match(socket, %{action: action, document: document, id: id, schema: schema}) do
    match? = id == socket.assigns.job._id && schema == Artemis.Job

    cond do
      match? && action == "delete" -> assign(socket, :job, document)
      match? && action == "create" -> assign(socket, :job, document)
      match? && action == "update" -> assign(socket, :job, document)
      true -> socket
    end
  end

  defp schedule_update() do
    milliseconds =
      Timex.now()
      |> DateTime.truncate(:millisecond)
      |> Timex.format!("%L", :strftime)
      |> String.to_integer()

    Process.send_after(self(), :refresh, 1_000 - milliseconds)
  end
end
