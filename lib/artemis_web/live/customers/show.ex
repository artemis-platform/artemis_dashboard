defmodule ArtemisWeb.CustomerLive.Show do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Context.subscribe(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Customer")
     |> assign(:resource, Context.get!(id))}
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
        {:updated, %{id: id} = resource},
        %{assigns: %{resource: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :resource, resource)}
  end

  def handle_info(
        {:deleted, %{id: id}},
        %{assigns: %{resource: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "Current resource was deleted.")
     |> push_navigate(to: ~p"/customers")}
  end

  def handle_info({type, %Artemis.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  def handle_info(_payload, socket), do: {:noreply, socket}
end
