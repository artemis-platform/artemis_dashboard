defmodule ArtemisWeb.HelpControllerTest do
  use ArtemisWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists help topics", %{conn: conn} do
      conn = get(conn, Routes.help_path(conn, :index))
      assert html_response(conn, 200) =~ "Help"
    end
  end
end
