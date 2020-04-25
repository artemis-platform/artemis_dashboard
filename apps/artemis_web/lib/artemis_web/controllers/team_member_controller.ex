defmodule ArtemisWeb.TeamMemberController do
  use ArtemisWeb, :controller

  alias Artemis.CreateUserTeam
  alias Artemis.DeleteUserTeam
  alias Artemis.GetTeam
  alias Artemis.GetUserTeam
  alias Artemis.UpdateUserTeam
  alias Artemis.UserTeam

  @preload [:team]

  def index(conn, %{"team_id" => team_id}) do
    redirect(conn, to: Routes.team_path(conn, :show, team_id))
  end

  def new(conn, %{"team_id" => team_id}) do
    authorize(conn, "user-teams:create", fn ->
      user = current_user(conn)
      team = GetTeam.call!(team_id, user)
      user_team = %UserTeam{team_id: team_id, type: "member"}
      changeset = UserTeam.changeset(user_team)

      assigns = [
        changeset: changeset,
        team: team,
        user_team: user_team
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"team_id" => team_id, "user_team" => params}) do
    authorize(conn, "user-teams:create", fn ->
      user = current_user(conn)
      team = GetTeam.call!(team_id, user)

      case CreateUserTeam.call(params, user) do
        {:ok, _team_user} ->
          conn
          |> put_flash(:info, "Team member created successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          user_team = %UserTeam{team_id: team_id}

          assigns = [
            changeset: changeset,
            team: team,
            user_team: user_team
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "user-teams:show", fn ->
      user_team = GetUserTeam.call!(id, current_user(conn))

      render(conn, "show.html", user_team: user_team)
    end)
  end

  def edit(conn, %{"team_id" => team_id, "id" => id}) do
    authorize(conn, "user-teams:update", fn ->
      user = current_user(conn)
      team = GetTeam.call!(team_id, user)
      user_team = GetUserTeam.call(id, user, preload: @preload)
      changeset = UserTeam.changeset(user_team)

      assigns = [
        changeset: changeset,
        team: team,
        user_team: user_team
      ]

      render(conn, "edit.html", assigns)
    end)
  end

  def update(conn, %{"id" => id, "team_id" => team_id, "user_team" => params}) do
    authorize(conn, "user-teams:update", fn ->
      user = current_user(conn)
      team = GetTeam.call!(team_id, user)

      case UpdateUserTeam.call(id, params, user) do
        {:ok, _team_user} ->
          conn
          |> put_flash(:info, "Team member updated successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          user_team = GetUserTeam.call(id, user, preload: @preload)

          assigns = [
            changeset: changeset,
            team: team,
            user_team: user_team
          ]

          render(conn, "edit.html", assigns)
      end
    end)
  end

  def delete(conn, %{"team_id" => team_id, "id" => id} = params) do
    authorize(conn, "user-teams:delete", fn ->
      {:ok, _team_user} = DeleteUserTeam.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Team member deleted successfully.")
      |> redirect(to: Routes.team_path(conn, :show, team_id))
    end)
  end
end
