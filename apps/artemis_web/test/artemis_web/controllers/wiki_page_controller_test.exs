defmodule ArtemisWeb.WikiPageControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{body: "some body text", section: "General", title: "Some Title"}
  @update_attrs %{body: "some updated text", section: "Updated Section", title: "Some Updated Title"}
  @invalid_attrs %{body: nil, section: nil, title: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all wiki pages", %{conn: conn} do
      conn = get(conn, Routes.wiki_page_path(conn, :index))
      assert html_response(conn, 200) =~ "Documentation"
    end
  end

  describe "new wiki page" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.wiki_page_path(conn, :new))
      assert html_response(conn, 200) =~ "New Documentation Page"
    end
  end

  describe "create wiki page" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.wiki_page_path(conn, :create), wiki_page: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.wiki_page_path(conn, :show, id)

      conn = get(conn, Routes.wiki_page_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Some Title"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.wiki_page_path(conn, :create), wiki_page: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Documentation Page"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows wiki page", %{conn: conn, record: record} do
      conn = get(conn, Routes.wiki_page_path(conn, :show, record))
      assert html_response(conn, 200) =~ record.title
    end
  end

  describe "edit wiki page" do
    setup [:create_record]

    test "renders form for editing chosen wiki page", %{conn: conn, record: record} do
      conn = get(conn, Routes.wiki_page_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Documentation"
    end
  end

  describe "update wiki page" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.wiki_page_path(conn, :update, record), wiki_page: @update_attrs)
      assert redirected_to(conn) == Routes.wiki_page_path(conn, :show, record)

      conn = get(conn, Routes.wiki_page_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Some Updated Title"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.wiki_page_path(conn, :update, record), wiki_page: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Documentation"
    end
  end

  describe "delete wiki page" do
    setup [:create_record]

    test "deletes chosen wiki page", %{conn: conn, record: record} do
      conn = delete(conn, Routes.wiki_page_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.wiki_page_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.wiki_page_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:wiki_page)

    {:ok, record: record}
  end
end
