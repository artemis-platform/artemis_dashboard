defmodule ArtemisWeb.WikiRevisionControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    setup [:create_record]

    test "lists all wiki revisions", %{conn: conn, parent: parent} do
      conn = get(conn, Routes.wiki_page_wiki_revision_path(conn, :index, parent))
      assert html_response(conn, 200) =~ "Documentation Revisions"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows wiki revision", %{conn: conn, parent: parent, record: record} do
      conn = get(conn, Routes.wiki_page_wiki_revision_path(conn, :show, parent, record))
      assert html_response(conn, 200) =~ record.title
    end
  end

  describe "delete wiki revision" do
    setup [:create_record]

    test "deletes chosen wiki revision", %{conn: conn, parent: parent, record: record} do
      conn = delete(conn, Routes.wiki_page_wiki_revision_path(conn, :delete, parent, record))
      assert redirected_to(conn) == Routes.wiki_page_wiki_revision_path(conn, :index, parent)
      assert_error_sent 404, fn ->
        get(conn, Routes.wiki_page_wiki_revision_path(conn, :show, parent, record))
      end
    end
  end

  defp create_record(_) do
    parent = insert(:wiki_page)
    record = insert(:wiki_revision, wiki_page: parent)

    {:ok, parent: parent, record: record}
  end
end
