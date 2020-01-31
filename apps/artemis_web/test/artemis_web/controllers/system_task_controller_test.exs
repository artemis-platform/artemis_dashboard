defmodule ArtemisWeb.SystemTaskControllerTest do
  use ArtemisWeb.ConnCase

  @create_attrs %{extra_params: %{hello: :world}, type: "some name"}
  @invalid_attrs %{extra_params: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all records", %{conn: conn} do
      conn = get(conn, Routes.system_task_path(conn, :index))
      assert html_response(conn, 200) =~ "System Tasks"
    end
  end

  describe "new record" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.system_task_path(conn, :new))
      assert html_response(conn, 200) =~ "New System Task"
    end
  end

  describe "create record" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post(conn, Routes.system_task_path(conn, :create), system_task: @create_attrs)

      assert redirected_to(conn) == Routes.system_task_path(conn, :index)
      assert html_response(conn, 200) =~ "Success"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.system_task_path(conn, :create), system_task: @invalid_attrs)
      assert html_response(conn, 200) =~ "New System Task"
    end
  end
end
