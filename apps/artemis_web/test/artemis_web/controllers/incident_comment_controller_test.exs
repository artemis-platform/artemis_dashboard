defmodule ArtemisWeb.IncidentCommentControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{body: "some body text", title: "Some Title", topic: "General"}
  @update_attrs %{body: "some updated text", title: "Some Updated Title", topic: "General"}
  @invalid_attrs %{body: nil, title: nil, topic: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "create comment" do
    setup do
      parent = insert(:incident)

      {:ok, parent: parent}
    end

    test "redirects to show when data is valid", %{conn: conn, parent: parent} do
      conn = post(conn, Routes.incident_comment_path(conn, :create, parent), comment: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.incident_path(conn, :show, id)

      conn = get(conn, Routes.incident_path(conn, :show, id))
      assert html_response(conn, 200) =~ @create_attrs.title
    end

    test "renders errors when data is invalid", %{conn: conn, parent: parent} do
      conn = post(conn, Routes.incident_comment_path(conn, :create, parent), comment: @invalid_attrs)
      assert html_response(conn, 200) =~ "Error"
    end
  end

  describe "edit comment" do
    setup [:create_record]

    test "renders form for editing chosen comment", %{conn: conn, parent: parent, record: record} do
      conn = get(conn, Routes.incident_comment_path(conn, :edit, parent, record))
      assert html_response(conn, 200) =~ "Edit Comment"
    end
  end

  describe "update comment" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, parent: parent, record: record} do
      conn = put(conn, Routes.incident_comment_path(conn, :update, parent, record), comment: @update_attrs)
      assert redirected_to(conn) == Routes.incident_path(conn, :show, parent)

      conn = get(conn, Routes.incident_path(conn, :show, parent))
      assert html_response(conn, 200) =~ @update_attrs.title
    end

    test "renders errors when data is invalid", %{conn: conn, parent: parent, record: record} do
      conn = put(conn, Routes.incident_comment_path(conn, :update, parent, record), comment: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Comment"
      assert html_response(conn, 200) =~ "Error"
    end
  end

  describe "delete comment" do
    setup [:create_record]

    test "deletes chosen comment", %{conn: conn, parent: parent, record: record} do
      conn = delete(conn, Routes.incident_comment_path(conn, :delete, parent, record))
      assert redirected_to(conn) == Routes.incident_path(conn, :show, parent)
    end
  end

  defp create_record(_) do
    parent = insert(:incident)
    record = insert(:comment, incidents: [parent])

    {:ok, parent: parent, record: record}
  end
end
