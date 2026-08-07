defmodule ArtemisWeb.CustomerLive.Index do
  use ArtemisWeb, :live_view

  alias Artemis.Customers, as: Context

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Context.subscribe(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Customers")
     |> stream(:resources, list_resources(socket.assigns.current_scope))}
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
    resource = Context.get!(socket.assigns.current_scope, id)
    {:ok, _} = Context.delete(socket.assigns.current_scope, resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  @impl true
  def handle_info({type, %Artemis.Customer{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :resources, list_resources(socket.assigns.current_scope), reset: true)}
  end

  defp list_resources(current_scope) do
    Context.list(current_scope)
  end
end
