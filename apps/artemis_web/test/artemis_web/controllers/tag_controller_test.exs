defmodule ArtemisWeb.TagControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "some name", slug: "test-slug", type: "test-type"}
  @update_attrs %{name: "some updated name", slug: "test-slug", type: "test-type"}
  @invalid_attrs %{name: nil, slug: nil, type: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all tags", %{conn: conn} do
      conn = get(conn, Routes.tag_path(conn, :index))
      assert html_response(conn, 200) =~ "Tags"
    end
  end

  describe "new tag" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.tag_path(conn, :new))
      assert html_response(conn, 200) =~ "New Tag"
    end
  end

  describe "create tag" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.tag_path(conn, :create), tag: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.tag_path(conn, :show, id)

      conn = get(conn, Routes.tag_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.tag_path(conn, :create), tag: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Tag"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows tag", %{conn: conn, record: record} do
      conn = get(conn, Routes.tag_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit tag" do
    setup [:create_record]

    test "renders form for editing chosen tag", %{conn: conn, record: record} do
      conn = get(conn, Routes.tag_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Tag"
    end
  end

  describe "update tag" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.tag_path(conn, :update, record), tag: @update_attrs)
      assert redirected_to(conn) == Routes.tag_path(conn, :show, record)

      conn = get(conn, Routes.tag_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.tag_path(conn, :update, record), tag: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Tag"
    end
  end

  describe "delete tag" do
    setup [:create_record]

    test "deletes chosen tag", %{conn: conn, record: record} do
      conn = delete(conn, Routes.tag_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.tag_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.tag_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:tag)

    {:ok, record: record}
  end
end
