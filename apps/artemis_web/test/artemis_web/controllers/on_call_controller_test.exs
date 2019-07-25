defmodule ArtemisWeb.OnCallControllerTest do
  use ArtemisWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all features", %{conn: conn} do
      conn = get(conn, Routes.on_call_path(conn, :index))
      assert html_response(conn, 200) =~ "On Call"
    end
  end
end
