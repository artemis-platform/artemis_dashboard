defmodule ArtemisWeb.CustomerLive.Show do
  use ArtemisWeb, :live_view

  alias Artemis.Customers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Customers.subscribe(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Customer")
     |> assign(:customer, Customers.get!(socket.assigns.current_scope, id))}
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
  def handle_info(
        {:updated, %Artemis.Customer{id: id} = customer},
        %{assigns: %{customer: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :customer, customer)}
  end

  def handle_info(
        {:deleted, %Artemis.Customer{id: id}},
        %{assigns: %{customer: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current customer was deleted.")
     |> push_navigate(to: ~p"/customers")}
  end

  def handle_info({type, %Artemis.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
