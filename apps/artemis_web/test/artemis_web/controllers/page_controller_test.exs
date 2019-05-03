defmodule ArtemisWeb.PageControllerTest do
  use ArtemisWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Artemis"
  end
end
