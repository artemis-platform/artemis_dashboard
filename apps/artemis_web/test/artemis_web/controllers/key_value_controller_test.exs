defmodule ArtemisWeb.KeyValueControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{key: "some key", value: "test-value"}
  @update_attrs %{key: "some updated key", value: "updated-value"}
  @invalid_attrs %{key: nil, slug: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all key-values", %{conn: conn} do
      conn = get(conn, Routes.key_value_path(conn, :index))
      assert html_response(conn, 200) =~ "Key Values"
    end
  end

  describe "new key-value" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.key_value_path(conn, :new))
      assert html_response(conn, 200) =~ "New Key Value"
    end
  end

  describe "create key-value" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.key_value_path(conn, :create), key_value: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.key_value_path(conn, :show, id)

      conn = get(conn, Routes.key_value_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Key"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.key_value_path(conn, :create), key_value: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Key Value"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows key-value", %{conn: conn, record: record} do
      conn = get(conn, Routes.key_value_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Key"
    end
  end

  describe "edit key-value" do
    setup [:create_record]

    test "renders form for editing chosen key-value", %{conn: conn, record: record} do
      conn = get(conn, Routes.key_value_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Key Value"
    end
  end

  describe "update key-value" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.key_value_path(conn, :update, record), key_value: @update_attrs)
      assert redirected_to(conn) == Routes.key_value_path(conn, :show, record)

      conn = get(conn, Routes.key_value_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated key"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.key_value_path(conn, :update, record), key_value: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Key Value"
    end
  end

  describe "delete key-value" do
    setup [:create_record]

    test "deletes chosen key-value", %{conn: conn, record: record} do
      conn = delete(conn, Routes.key_value_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.key_value_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.key_value_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:key_value)

    {:ok, record: record}
  end
end
