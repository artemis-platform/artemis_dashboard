defmodule ArtemisWeb.SystemTaskControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @invalid_attrs %{extra_params: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all system tasks", %{conn: conn} do
      conn = get(conn, Routes.system_task_path(conn, :index))
      assert html_response(conn, 200) =~ "System Tasks"
    end
  end

  describe "new" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.system_task_path(conn, :new))
      assert html_response(conn, 200) =~ "New System Task"
    end
  end

  describe "create" do
    test "redirects to index when data is valid", %{conn: conn} do
      valid_params = params_for(:system_task)

      conn = post(conn, Routes.system_task_path(conn, :create), system_task: valid_params)

      assert redirected_to(conn) == Routes.system_task_path(conn, :index)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.system_task_path(conn, :create), system_task: @invalid_attrs)
      assert html_response(conn, 200) =~ "New System Task"
    end
  end
end
