defmodule ArtemisWeb.CustomersLive.Show do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket), do: Context.subscribe(params)

    socket =
      socket
      |> assign(:page_title, gettext("Customer"))
      |> stream(:resources, get_resource!(params, socket.assigns.current_scope))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign(:uri, uri)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated, %{id: id} = resource}, %{assigns: %{resource: %{id: id}}} = socket) do
    updated_socket =
      socket
      |> put_flash(:error, gettext("Resource updated"))
      |> assign(:resource, resource)

    {:noreply, updated_socket}
  end

  def handle_info({:deleted, %{id: id}}, %{assigns: %{resource: %{id: id}}} = socket) do
    updated_socket =
      socket
      |> put_flash(:error, gettext("Resource was deleted"))
      |> push_navigate(to: ~p"/customers")

    {:noreply, updated_socket}
  end

  def handle_info(_payload, socket), do: {:noreply, socket}

  # Helpers

  def get_resource!(%{"id" => id} = _params, _current_scope) do
    Context.get!(id)
  end
end
