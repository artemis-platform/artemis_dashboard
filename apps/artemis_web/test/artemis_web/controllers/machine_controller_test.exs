defmodule ArtemisWeb.MachineControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "some name", slug: "test-slug"}
  @update_attrs %{name: "some updated name", slug: "test-slug"}
  @invalid_attrs %{name: nil, slug: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all machines", %{conn: conn} do
      conn = get(conn, Routes.machine_path(conn, :index))
      assert html_response(conn, 200) =~ "Machines"
    end
  end

  describe "new machine" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.machine_path(conn, :new))
      assert html_response(conn, 200) =~ "New Machine"
    end
  end

  describe "create machine" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.machine_path(conn, :create), machine: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.machine_path(conn, :show, id)

      conn = get(conn, Routes.machine_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.machine_path(conn, :create), machine: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Machine"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows machine", %{conn: conn, record: record} do
      conn = get(conn, Routes.machine_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit machine" do
    setup [:create_record]

    test "renders form for editing chosen machine", %{conn: conn, record: record} do
      conn = get(conn, Routes.machine_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Machine"
    end
  end

  describe "update machine" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.machine_path(conn, :update, record), machine: @update_attrs)
      assert redirected_to(conn) == Routes.machine_path(conn, :show, record)

      conn = get(conn, Routes.machine_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.machine_path(conn, :update, record), machine: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Machine"
    end
  end

  describe "delete machine" do
    setup [:create_record]

    test "deletes chosen machine", %{conn: conn, record: record} do
      conn = delete(conn, Routes.machine_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.machine_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.machine_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:machine)

    {:ok, record: record}
  end
end
