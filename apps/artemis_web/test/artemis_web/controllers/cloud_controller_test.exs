defmodule ArtemisWeb.CloudControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "some name", slug: "test-slug"}
  @update_attrs %{name: "some updated name", slug: "test-slug"}
  @invalid_attrs %{name: nil, slug: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all clouds", %{conn: conn} do
      conn = get(conn, Routes.cloud_path(conn, :index))
      assert html_response(conn, 200) =~ "Clouds"
    end
  end

  describe "new cloud" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.cloud_path(conn, :new))
      assert html_response(conn, 200) =~ "New Cloud"
    end
  end

  describe "create cloud" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.cloud_path(conn, :create), cloud: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.cloud_path(conn, :show, id)

      conn = get(conn, Routes.cloud_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.cloud_path(conn, :create), cloud: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Cloud"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows cloud", %{conn: conn, record: record} do
      conn = get(conn, Routes.cloud_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit cloud" do
    setup [:create_record]

    test "renders form for editing chosen cloud", %{conn: conn, record: record} do
      conn = get(conn, Routes.cloud_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Cloud"
    end
  end

  describe "update cloud" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.cloud_path(conn, :update, record), cloud: @update_attrs)
      assert redirected_to(conn) == Routes.cloud_path(conn, :show, record)

      conn = get(conn, Routes.cloud_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.cloud_path(conn, :update, record), cloud: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Cloud"
    end
  end

  describe "delete cloud" do
    setup [:create_record]

    test "deletes chosen cloud", %{conn: conn, record: record} do
      conn = delete(conn, Routes.cloud_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.cloud_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.cloud_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:cloud)

    {:ok, record: record}
  end
end
