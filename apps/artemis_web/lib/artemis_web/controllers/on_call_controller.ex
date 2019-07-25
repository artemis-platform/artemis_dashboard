defmodule ArtemisWeb.OnCallController do
  use ArtemisWeb, :controller

  def index(conn, _params) do
    authorize_any(conn, ["incidents:list"], fn ->
      render(conn, "index.html")
    end)
  end
end
