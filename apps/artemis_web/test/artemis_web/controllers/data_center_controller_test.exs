defmodule ArtemisWeb.DataCenterControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "some name", slug: "test-slug"}
  @update_attrs %{name: "some updated name", slug: "test-slug"}
  @invalid_attrs %{name: nil, slug: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all data centers", %{conn: conn} do
      conn = get(conn, Routes.data_center_path(conn, :index))
      assert html_response(conn, 200) =~ "Data Centers"
    end
  end

  describe "new data center" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.data_center_path(conn, :new))
      assert html_response(conn, 200) =~ "New Data Center"
    end
  end

  describe "create data center" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.data_center_path(conn, :create), data_center: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.data_center_path(conn, :show, id)

      conn = get(conn, Routes.data_center_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.data_center_path(conn, :create), data_center: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Data Center"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows data center", %{conn: conn, record: record} do
      conn = get(conn, Routes.data_center_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit data center" do
    setup [:create_record]

    test "renders form for editing chosen data center", %{conn: conn, record: record} do
      conn = get(conn, Routes.data_center_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Data Center"
    end
  end

  describe "update data center" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.data_center_path(conn, :update, record), data_center: @update_attrs)
      assert redirected_to(conn) == Routes.data_center_path(conn, :show, record)

      conn = get(conn, Routes.data_center_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.data_center_path(conn, :update, record), data_center: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Data Center"
    end
  end

  describe "delete data center" do
    setup [:create_record]

    test "deletes chosen data center", %{conn: conn, record: record} do
      conn = delete(conn, Routes.data_center_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.data_center_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.data_center_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:data_center)

    {:ok, record: record}
  end
end
