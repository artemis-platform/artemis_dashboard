defmodule ArtemisWeb.CustomerLive.Index do
  use ArtemisWeb, :live_view

  alias Artemis.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Customers
        <:actions>
          <.button variant="primary" navigate={~p"/customers/new"}>
            <.icon name="hero-plus" /> New Customer
          </.button>
        </:actions>
      </.header>

      <.table
        id="customers"
        rows={@streams.customers}
        row_click={fn {_id, customer} -> JS.navigate(~p"/customers/#{customer}") end}
      >
        <:col :let={{_id, customer}} label="Name">{customer.name}</:col>
        <:col :let={{_id, customer}} label="Notes">{customer.notes}</:col>
        <:action :let={{_id, customer}}>
          <div class="sr-only">
            <.link navigate={~p"/customers/#{customer}"}>Show</.link>
          </div>
          <.link navigate={~p"/customers/#{customer}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, customer}}>
          <.link
            phx-click={JS.push("delete", value: %{id: customer.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Customers.subscribe_customers(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Customers")
     |> stream(:customers, list_customers(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    customer = Customers.get_customer!(socket.assigns.current_scope, id)
    {:ok, _} = Customers.delete_customer(socket.assigns.current_scope, customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end

  @impl true
  def handle_info({type, %Artemis.Customers.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :customers, list_customers(socket.assigns.current_scope), reset: true)}
  end

  defp list_customers(current_scope) do
    Customers.list_customers(current_scope)
  end
end
