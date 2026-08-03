defmodule ArtemisWeb.CustomerLive.Index do
  use ArtemisWeb, :live_view

  alias Artemis.Customers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Customers.subscribe(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Customers")
     |> stream(:customers, list(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(params, uri, socket) do
    updated_socket =
      socket
      |> assign(:params, params)
      |> assign(:uri, uri)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    customer = Customers.get!(socket.assigns.current_scope, id)
    {:ok, _} = Customers.delete(socket.assigns.current_scope, customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end

  @impl true
  def handle_info({type, %Artemis.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :customers, list(socket.assigns.current_scope), reset: true)}
  end

  defp list(current_scope) do
    Customers.list(current_scope)
  end
end
