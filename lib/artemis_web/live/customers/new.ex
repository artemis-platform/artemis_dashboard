defmodule ArtemisWeb.CustomersLive.New do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("New Customer"))
      |> assign(:params, params)
      |> assign(:uri, uri)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:dynamic_form, payload}, socket) do
    ArtemisWeb.Helpers.Form.create_and_redirect(socket, ~p"/customers", fn ->
      Context.create(payload.data)
    end)
  end
end
