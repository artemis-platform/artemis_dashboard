defmodule ArtemisWeb.ErrorViewTest do
  use ArtemisWeb.ConnCase, async: true

  import Phoenix.View

  setup %{conn: conn} do
    conn =
      conn
      |> sign_in()
      |> Plug.Conn.put_private(:phoenix_endpoint, ArtemisWeb.Endpoint)

    {:ok, conn: conn}
  end

  test "renders 401.html", %{conn: conn} do
    assert render_to_string(ArtemisWeb.ErrorView, "401.html", conn: conn) =~ "Unauthorized"
  end

  test "renders 403.html", %{conn: conn} do
    assert render_to_string(ArtemisWeb.ErrorView, "403.html", conn: conn) =~ "Forbidden"
  end

  test "renders 404.html", %{conn: conn} do
    assert render_to_string(ArtemisWeb.ErrorView, "404.html", conn: conn) =~ "Not Found"
  end

  test "renders 500.html", %{conn: conn} do
    assert render_to_string(ArtemisWeb.ErrorView, "500.html", conn: conn) =~ "Internal Server Error"
  end
end
