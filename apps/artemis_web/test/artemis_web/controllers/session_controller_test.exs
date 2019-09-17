defmodule ArtemisWeb.SessionControllerTest do
  use ArtemisWeb.ConnCase

  import ArtemisLog.Factories

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all sessions", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :index))
      assert html_response(conn, 200) =~ "Sessions"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows sessions", %{conn: conn, record: record} do
      conn = get(conn, Routes.session_path(conn, :show, record.session_id))
      assert html_response(conn, 200) =~ "Session"
    end
  end

  defp create_record(_) do
    record = insert(:event_log)

    {:ok, record: record}
  end
end
