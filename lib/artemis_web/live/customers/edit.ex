defmodule ArtemisWeb.CustomersLive.Edit do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def handle_params(params, uri, socket) do
    resource = Context.get!(params["id"])

    socket =
      socket
      |> assign(:page_title, gettext("Edit"))
      |> assign(:params, params)
      |> assign(:uri, uri)
      |> assign(:resource, resource)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:dynamic_form, payload}, socket) do
    ArtemisWeb.Helpers.Form.update_and_redirect(socket, ~p"/customers", fn ->
      Context.update(socket.assigns.resource, payload.data)
    end)
  end
end
