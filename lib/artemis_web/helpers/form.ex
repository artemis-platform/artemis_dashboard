defmodule ArtemisWeb.Helpers.Form do
  @moduledoc """
  Helpers for forms
  """
  use ArtemisWeb, :html

  require Logger

  def create_and_redirect(socket, base_path, callback) do
    case callback.() do
      {:ok, resource} ->
        updated_socket =
          socket
          |> Phoenix.LiveView.put_flash(:info, gettext("Resource created"))
          |> Phoenix.LiveView.redirect(to: "#{base_path}/#{resource.id}")

        {:noreply, updated_socket}

      error ->
        Logger.debug("Error when creating resource: #{inspect(error)}")

        updated_socket = Phoenix.LiveView.put_flash(socket, :error, gettext("Error creating resource"))

        {:noreply, updated_socket}
    end
  end

  def update_and_redirect(socket, base_path, callback) do
    case callback.() do
      {:ok, resource} ->
        updated_socket =
          socket
          |> Phoenix.LiveView.put_flash(:info, gettext("Resource updated"))
          |> Phoenix.LiveView.redirect(to: "#{base_path}/#{resource.id}")

        {:noreply, updated_socket}

      error ->
        Logger.debug("Error when updating resource: #{inspect(error)}")

        updated_socket = Phoenix.LiveView.put_flash(socket, :error, gettext("Error updating resource"))

        {:noreply, updated_socket}
    end
  end
end
