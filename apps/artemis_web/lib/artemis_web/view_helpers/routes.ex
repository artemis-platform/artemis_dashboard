defmodule ArtemisWeb.ViewHelper.Routes do
  alias ArtemisWeb.Router.Helpers, as: Routes

  @moduledoc """
  View helpers to simplify interface with ArtemisWeb.Router.Helpers
  """

  @doc """
  Route path helper that works with sockets or conns interchangeably.

  ## Examples

  Original route path helper:

    Routes.tag_path(get_conn_or_socket(assigns), :index_bulk_actions)

  Becomes:

    route(assigns, :tag_path, :index_bulk_actions)

  """
  def route(assigns, helper, action, options \\ []) do
    conn_or_socket = ArtemisWeb.ViewHelper.Async.get_conn_or_socket(assigns)

    Kernel.apply(Routes, helper, [conn_or_socket, action, options])
  end
end
