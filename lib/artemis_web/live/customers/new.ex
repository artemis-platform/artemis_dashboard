defmodule ArtemisWeb.CustomerLive.New do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:page_title, "New")
      |> assign(:params, params)
      |> assign(:uri, uri)

    {:noreply, socket}
  end
end
