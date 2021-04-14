defmodule ArtemisWeb.ViewHelper.Routes do
  alias ArtemisWeb.Router.Helpers, as: Routes

  @moduledoc """
  View helpers to simplify interface with ArtemisWeb.Router.Helpers
  """

  @doc """
  Route path helper that works with sockets or connections interchangeably.

  ## Examples

  Current route path helper that supports both socket and connections:

    Routes.tag_path(get_conn_or_socket(assigns), :index_bulk_actions)

  Becomes:

    route(:tag_path, :index_bulk_actions, assigns)

  """
  def route(path_helper, action, assigns, options \\ []) do
    conn_or_socket = ArtemisWeb.ViewHelper.Async.get_conn_or_socket(assigns)

    Kernel.apply(Routes, path_helper, [conn_or_socket, action, options])
  end
end
