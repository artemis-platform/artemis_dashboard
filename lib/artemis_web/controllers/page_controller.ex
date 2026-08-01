defmodule ArtemisWeb.PageController do
  use ArtemisWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
