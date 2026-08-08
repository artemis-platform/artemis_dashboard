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

    {:ok, socket}
  end
end
