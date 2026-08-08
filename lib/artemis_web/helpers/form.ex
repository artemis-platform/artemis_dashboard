defmodule ArtemisWeb.Helpers.Form do
  use ArtemisWeb, :html

  require Logger

  def create_and_redirect(socket, base_path, callback) do
    with {:ok, resource} <- callback.() do
      updated_socket =
        socket
        |> Phoenix.LiveView.put_flash(:info, gettext("Resource created"))
        |> Phoenix.LiveView.redirect(to: "#{base_path}/#{resource.id}")

      {:noreply, updated_socket}
    else
      error ->
        Logger.debug("Error when creating resource: #{inspect(error)}")

        updated_socket = Phoenix.LiveView.put_flash(socket, :error, gettext("Error creating resource"))

        {:noreply, updated_socket}
    end
  end

  def update_and_redirect(socket, base_path, callback) do
    with {:ok, resource} <- callback.() do
      updated_socket =
        socket
        |> Phoenix.LiveView.put_flash(:info, gettext("Resource updated"))
        |> Phoenix.LiveView.redirect(to: "#{base_path}/#{resource.id}")

      {:noreply, updated_socket}
    else
      error ->
        Logger.debug("Error when updating resource: #{inspect(error)}")

        updated_socket = Phoenix.LiveView.put_flash(socket, :error, gettext("Error updating resource"))

        {:noreply, updated_socket}
    end
  end
end
