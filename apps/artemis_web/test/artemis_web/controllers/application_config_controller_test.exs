defmodule ArtemisWeb.ApplicationConfigControllerTest do
  use ArtemisWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all application config", %{conn: conn} do
      conn = get(conn, Routes.application_config_path(conn, :index))
      assert html_response(conn, 200) =~ "Application Configs"
    end
  end

  describe "show" do
    test "shows application config", %{conn: conn} do
      conn = get(conn, Routes.application_config_path(conn, :show, :artemis))
      assert html_response(conn, 200) =~ "artemis"
    end
  end
end
