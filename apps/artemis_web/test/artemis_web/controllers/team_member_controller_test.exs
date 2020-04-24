defmodule ArtemisWeb.TeamMemberControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  setup %{conn: conn} do
    team = insert(:team)

    {:ok, conn: sign_in(conn), team: team}
  end

  describe "index" do
    test "redirects to team template show", %{conn: conn, team: team} do
      conn = get(conn, Routes.team_member_path(conn, :index, team))
      assert redirected_to(conn) == Routes.team_path(conn, :show, team)
    end
  end

  describe "new team member" do
    test "renders new form", %{conn: conn, team: team} do
      conn = get(conn, Routes.team_member_path(conn, :new, team))
      assert html_response(conn, 200) =~ "New Team User"
    end
  end

  describe "create team member" do
    test "redirects to show when data is valid", %{conn: conn, team: team} do
      params = params_for(:user_team, team: team)

      conn = post(conn, Routes.team_member_path(conn, :create, team), user_team: params)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.team_path(conn, :show, team)

      conn = get(conn, Routes.team_path(conn, :show, team))
      assert html_response(conn, 200) =~ "Title"
    end

    test "renders errors when data is invalid", %{conn: conn, team: team} do
      conn = post(conn, Routes.team_member_path(conn, :create, team), user_team: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Team User"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows team member", %{conn: conn, team: team, record: record} do
      conn = get(conn, Routes.team_member_path(conn, :show, team, record))
      assert html_response(conn, 200) =~ "Title"
    end
  end

  describe "edit team member" do
    setup [:create_record]

    test "renders form for editing chosen team member", %{conn: conn, team: team, record: record} do
      conn = get(conn, Routes.team_member_path(conn, :edit, team, record))
      assert html_response(conn, 200) =~ "Edit Team User"
    end
  end

  describe "update team member" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, team: team, record: record} do
      conn = put(conn, Routes.team_member_path(conn, :update, team, record), user_team: @update_attrs)
      assert redirected_to(conn) == Routes.team_path(conn, :show, team)

      conn = get(conn, Routes.team_path(conn, :show, team))
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, team: team, record: record} do
      conn = put(conn, Routes.team_member_path(conn, :update, team, record), user_team: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Team User"
    end
  end

  describe "delete team member" do
    setup [:create_record]

    test "deletes chosen team member", %{conn: conn, team: team, record: record} do
      conn = delete(conn, Routes.team_member_path(conn, :delete, team, record))
      assert redirected_to(conn) == Routes.team_path(conn, :show, team)

      assert_error_sent 404, fn ->
        get(conn, Routes.team_member_path(conn, :show, team, record))
      end
    end
  end

  defp create_record(params) do
    record = insert(:user_team, team: params[:team])

    {:ok, record: record}
  end
end
