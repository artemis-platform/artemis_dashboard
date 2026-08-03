defmodule ArtemisWeb.CustomerLive.Show do
  use ArtemisWeb, :live_view

  alias Artemis.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Customer {@customer.id}
        <:subtitle>This is a customer record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/customers"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/customers/#{@customer}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit customer
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@customer.name}</:item>
        <:item title="Notes">{@customer.notes}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Customers.subscribe_customers(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Customer")
     |> assign(:customer, Customers.get_customer!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Artemis.Customers.Customer{id: id} = customer},
        %{assigns: %{customer: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :customer, customer)}
  end

  def handle_info(
        {:deleted, %Artemis.Customers.Customer{id: id}},
        %{assigns: %{customer: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current customer was deleted.")
     |> push_navigate(to: ~p"/customers")}
  end

  def handle_info({type, %Artemis.Customers.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
