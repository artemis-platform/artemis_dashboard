defmodule ArtemisWeb.TeamController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.TeamView.available_bulk_actions(),
    path: &Routes.team_path(&1, :index),
    permission: "teams:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.team_path/3,
    permission: "teams:list",
    resource_type: "Team"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.team_event_log_path/4,
    permission: "teams:show",
    resource_getter: &Artemis.GetTeam.call!/2,
    resource_id: "team_id",
    resource_type: "Team",
    resource_variable: :team

  alias Artemis.CreateTeam
  alias Artemis.Team
  alias Artemis.DeleteTeam
  alias Artemis.GetTeam
  alias Artemis.ListTeams
  alias Artemis.UpdateTeam

  @preload []

  def index(conn, params) do
    authorize(conn, "teams:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      teams = ListTeams.call(params, user)
      allowed_bulk_actions = ArtemisWeb.TeamView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        teams: teams
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "teams:create", fn ->
      team = %Team{}
      changeset = Team.changeset(team)

      render(conn, "new.html", changeset: changeset, team: team)
    end)
  end

  def create(conn, %{"team" => params}) do
    authorize(conn, "teams:create", fn ->
      create_params = Map.delete(params, "user_teams")

      case CreateTeam.call(create_params, current_user(conn)) do
        {:ok, team} ->
          conn
          |> put_flash(:info, "Team created successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team))

        {:error, %Ecto.Changeset{} = changeset} ->
          team = %Team{}

          render(conn, "new.html", changeset: changeset, team: team)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "teams:show", fn ->
      team = GetTeam.call!(id, current_user(conn), preload: [:users])

      render(conn, "show.html", team: team)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "teams:update", fn ->
      team = GetTeam.call(id, current_user(conn), preload: @preload)
      changeset = Team.changeset(team)

      render(conn, "edit.html", changeset: changeset, team: team)
    end)
  end

  def update(conn, %{"id" => id, "team" => params}) do
    authorize(conn, "teams:update", fn ->
      update_params = Map.delete(params, "user_teams")

      case UpdateTeam.call(id, update_params, current_user(conn)) do
        {:ok, team} ->
          conn
          |> put_flash(:info, "Team updated successfully.")
          |> redirect(to: Routes.team_path(conn, :show, team))

        {:error, %Ecto.Changeset{} = changeset} ->
          team = GetTeam.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, team: team)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "teams:delete", fn ->
      {:ok, _team} = DeleteTeam.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Team deleted successfully.")
      |> redirect(to: Routes.team_path(conn, :index))
    end)
  end
end
