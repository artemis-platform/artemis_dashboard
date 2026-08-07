defmodule ArtemisWeb.CustomerLive.Index do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      Context.subscribe(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Customers")
     |> stream(:resources, list_resources(params, socket.assigns.current_scope))}
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
    resource = Context.get(id)
    {:ok, _} = Context.delete(resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  @impl true
  def handle_info({type, %Artemis.Customer{}}, socket) when type in [:created, :updated, :deleted] do
    current_scope = socket.assigns.current_scope
    params = socket.assigns.params
    resources = list_resources(params, current_scope)

    {:noreply, stream(socket, :resources, resources, reset: true)}
  end

  def handle_info(_payload, socket), do: {:noreply, socket}

  # Helpers

  defp list_resources(params, _current_scope) do
    Context.list(params)
  end
end
