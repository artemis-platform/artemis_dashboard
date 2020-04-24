defmodule ArtemisWeb.TeamMemberController do
  use ArtemisWeb, :controller

  alias Artemis.CreateUserTeam
  alias Artemis.DeleteUserTeam
  alias Artemis.GetTeam
  alias Artemis.GetUserTeam
  alias Artemis.UpdateUserTeam
  alias Artemis.UserTeam

  @preload [:team_template]

  def index(conn, %{"team_id" => team_id}) do
    redirect(conn, to: Routes.team_path(conn, :show, team_id))
  end

  def new(conn, %{"team_id" => team_id}) do
    authorize(conn, "user-teams:create", fn ->
      user = current_user(conn)
      team_template = GetTeam.call!(team_id, user)
      team_user = %UserTeam{team_id: team_id}
      changeset = UserTeam.changeset(team_user)

      assigns = [
        changeset: changeset,
        team_user: team_user,
        team_template: team_template
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"team_user" => params, "team_id" => team_id}) do
    authorize(conn, "user-teams:create", fn ->
      user = current_user(conn)
      team_template = GetTeam.call!(team_id, user)

      case CreateUserTeam.call(params, user) do
        {:ok, _team_user} ->
          conn
          |> put_flash(:info, "Team member created successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          team_user = %UserTeam{team_id: team_id}

          assigns = [
            changeset: changeset,
            team_user: team_user,
            team_template: team_template
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "user-teams:show", fn ->
      team_user = GetUserTeam.call!(id, current_user(conn), preload: @preload)

      render(conn, "show.html", team_user: team_user)
    end)
  end

  def edit(conn, %{"team_id" => team_id, "id" => id}) do
    authorize(conn, "user-teams:update", fn ->
      user = current_user(conn)
      team_template = GetTeam.call!(team_id, user)
      team_user = GetUserTeam.call(id, user, preload: @preload)
      changeset = UserTeam.changeset(team_user)

      assigns = [
        changeset: changeset,
        team_user: team_user,
        team_template: team_template
      ]

      render(conn, "edit.html", assigns)
    end)
  end

  def update(conn, %{"id" => id, "team_id" => team_id, "team_user" => params}) do
    authorize(conn, "user-teams:update", fn ->
      user = current_user(conn)
      team_template = GetTeam.call!(team_id, user)

      case UpdateUserTeam.call(id, params, user) do
        {:ok, _team_user} ->
          conn
          |> put_flash(:info, "Team member updated successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          team_user = GetUserTeam.call(id, user, preload: @preload)

          assigns = [
            changeset: changeset,
            team_user: team_user,
            team_template: team_template
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
