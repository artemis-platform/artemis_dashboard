defmodule ArtemisWeb.UserAccess do
  @moduledoc """
  A thin wrapper around `Artemis.UserAccess`.

  Adds the ability to pull the current user from connection context.
  """
  import ArtemisWeb.Guardian.Helpers, only: [current_user: 1]

  alias Artemis.User
  alias Phoenix.LiveView.Socket

  # Has?

  def has?(%Socket{} = socket, permission), do: Artemis.UserAccess.has?(get_user(socket), permission)
  def has?(%User{} = user, permission), do: Artemis.UserAccess.has?(user, permission)
  def has?(conn_or_assigns, permission), do: Artemis.UserAccess.has?(current_user(conn_or_assigns), permission)

  # Has any?

  def has_any?(%Socket{} = socket, permission), do: Artemis.UserAccess.has_any?(get_user(socket), permission)
  def has_any?(%User{} = user, permission), do: Artemis.UserAccess.has_any?(user, permission)
  def has_any?(conn_or_assigns, permission), do: Artemis.UserAccess.has_any?(current_user(conn_or_assigns), permission)

  # Has all?

  def has_all?(%Socket{} = socket, permission), do: Artemis.UserAccess.has_all?(get_user(socket), permission)
  def has_all?(%User{} = user, permission), do: Artemis.UserAccess.has_all?(user, permission)
  def has_all?(conn_or_assigns, permission), do: Artemis.UserAccess.has_all?(current_user(conn_or_assigns), permission)

  # Helpers

  defp get_user(%Socket{} = socket), do: Map.get(socket.assigns, :user)
end
