defmodule ArtemisWeb.IncidentControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all incidents", %{conn: conn} do
      conn = get(conn, Routes.incident_path(conn, :index))
      assert html_response(conn, 200) =~ "Incidents"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows incident", %{conn: conn, record: record} do
      conn = get(conn, Routes.incident_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Title"
    end
  end

  describe "delete incident" do
    setup [:create_record]

    test "deletes chosen incident", %{conn: conn, record: record} do
      conn = delete(conn, Routes.incident_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.incident_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.incident_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:incident)

    {:ok, record: record}
  end
end
