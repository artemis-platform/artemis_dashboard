defmodule ArtemisWeb.TeamControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "some name", slug: "test-slug"}
  @update_attrs %{name: "some updated name", slug: "test-slug"}
  @invalid_attrs %{name: nil, slug: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all teams", %{conn: conn} do
      conn = get(conn, Routes.team_path(conn, :index))
      assert html_response(conn, 200) =~ "Teams"
    end
  end

  describe "new team" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.team_path(conn, :new))
      assert html_response(conn, 200) =~ "New Team"
    end
  end

  describe "create team" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.team_path(conn, :create), team: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.team_path(conn, :show, id)

      conn = get(conn, Routes.team_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.team_path(conn, :create), team: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Team"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows team", %{conn: conn, record: record} do
      conn = get(conn, Routes.team_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit team" do
    setup [:create_record]

    test "renders form for editing chosen team", %{conn: conn, record: record} do
      conn = get(conn, Routes.team_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Team"
    end
  end

  describe "update team" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.team_path(conn, :update, record), team: @update_attrs)
      assert redirected_to(conn) == Routes.team_path(conn, :show, record)

      conn = get(conn, Routes.team_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.team_path(conn, :update, record), team: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Team"
    end
  end

  describe "delete team" do
    setup [:create_record]

    test "deletes chosen team", %{conn: conn, record: record} do
      conn = delete(conn, Routes.team_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.team_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.team_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:team)

    {:ok, record: record}
  end
end
