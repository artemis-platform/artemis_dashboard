defmodule ArtemisWeb.HelpController do
  use ArtemisWeb, :controller

  def index(conn, _params) do
    authorize(conn, "help:list", fn () ->
      render(conn, "index.html")
    end)
  end
end
