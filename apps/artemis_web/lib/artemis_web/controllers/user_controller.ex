defmodule ArtemisWeb.UserController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.UserView.available_bulk_actions(),
    path: &Routes.user_path(&1, :index),
    permission: "users:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.user_path/3,
    permission: "users:list",
    resource_type: "User"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.user_event_log_path/4,
    permission: "users:show",
    resource_getter: &Artemis.GetUser.call!/2,
    resource_id: "user_id",
    resource_type: "User",
    resource_variable: :user

  alias Artemis.CreateUser
  alias Artemis.User
  alias Artemis.DeleteUser
  alias Artemis.GetUser
  alias Artemis.ListRoles
  alias Artemis.ListTeams
  alias Artemis.ListUsers
  alias Artemis.UpdateUser

  @preload [:user_roles]

  def index(conn, params) do
    authorize(conn, "users:list", fn ->
      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, [:roles, :teams])

      user = current_user(conn)
      roles = ListRoles.call(user)
      teams = ListTeams.call(user)
      users = ListUsers.call(params, user)
      allowed_bulk_actions = ArtemisWeb.UserView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        roles: roles,
        teams: teams,
        users: users
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "users:create", fn ->
      user = %User{user_roles: []}
      changeset = User.changeset(user)
      roles = ListRoles.call(current_user(conn))
      teams = ListTeams.call(current_user(conn))

      assigns = [
        changeset: changeset,
        roles: roles,
        teams: teams,
        user: user
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"user" => params}) do
    authorize(conn, "users:create", fn ->
      params = checkbox_to_params(params, "user_roles")

      case CreateUser.call(params, current_user(conn)) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User created successfully.")
          |> redirect(to: Routes.user_path(conn, :show, user))

        {:error, %Ecto.Changeset{} = changeset} ->
          user = %User{user_roles: []}
          roles = ListRoles.call(current_user(conn))
          teams = ListTeams.call(current_user(conn))

          assigns = [
            changeset: changeset,
            roles: roles,
            teams: teams,
            user: user
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "users:show", fn ->
      user = GetUser.call!(id, current_user(conn), preload: [:permissions, :roles, :teams])

      render(conn, "show.html", user: user)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "users:update", fn ->
      user = GetUser.call(id, current_user(conn), preload: @preload)
      changeset = User.changeset(user)
      roles = ListRoles.call(current_user(conn))
      teams = ListTeams.call(current_user(conn))

      assigns = [
        changeset: changeset,
        roles: roles,
        teams: teams,
        user: user
      ]

      render(conn, "edit.html", assigns)
    end)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    authorize(conn, "users:update", fn ->
      params = checkbox_to_params(params, "user_roles")

      case UpdateUser.call(id, params, current_user(conn)) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User updated successfully.")
          |> redirect(to: Routes.user_path(conn, :show, user))

        {:error, %Ecto.Changeset{} = changeset} ->
          user = GetUser.call(id, current_user(conn), preload: @preload)
          roles = ListRoles.call(current_user(conn))
          teams = ListTeams.call(current_user(conn))

          assigns = [
            changeset: changeset,
            roles: roles,
            teams: teams,
            user: user
          ]

          render(conn, "edit.html", assigns)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "users:delete", fn ->
      user = current_user(conn)
      record = GetUser.call!(id, user)

      case record.id == user.id do
        false ->
          {:ok, _} = DeleteUser.call(id, params, user)

          conn
          |> put_flash(:info, "User deleted successfully.")
          |> redirect(to: Routes.user_path(conn, :index))

        true ->
          conn
          |> put_flash(:error, "Cannot delete own user")
          |> redirect(to: Routes.user_path(conn, :show, user))
      end
    end)
  end
end
