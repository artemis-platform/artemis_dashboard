defmodule ArtemisWeb.RoleController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.RoleView.available_bulk_actions(),
    path: &Routes.role_path(&1, :index),
    permission: "roles:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.role_path/3,
    permission: "roles:list",
    resource_type: "Role"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.role_event_log_path/4,
    permission: "roles:show",
    resource_getter: &Artemis.GetRole.call!/2,
    resource_id: "role_id",
    resource_type: "Role",
    resource_variable: :role

  alias Artemis.CreateRole
  alias Artemis.Role
  alias Artemis.DeleteRole
  alias Artemis.GetRole
  alias Artemis.ListPermissions
  alias Artemis.ListRoles
  alias Artemis.UpdateRole

  @preload [:permissions]

  def index(conn, params) do
    authorize(conn, "roles:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      roles = ListRoles.call(params, user)

      assigns = [
        roles: roles
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "roles:create", fn ->
      role = %Role{permissions: []}
      changeset = Role.changeset(role)
      permissions = ListPermissions.call(current_user(conn))

      render(conn, "new.html", changeset: changeset, permissions: permissions, role: role)
    end)
  end

  def create(conn, %{"role" => params}) do
    authorize(conn, "roles:create", fn ->
      params = Map.put_new(params, "permissions", [])

      case CreateRole.call(params, current_user(conn)) do
        {:ok, role} ->
          conn
          |> put_flash(:info, "Role created successfully.")
          |> redirect(to: Routes.role_path(conn, :show, role))

        {:error, %Ecto.Changeset{} = changeset} ->
          role = %Role{permissions: []}
          permissions = ListPermissions.call(current_user(conn))

          render(conn, "new.html", changeset: changeset, permissions: permissions, role: role)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "roles:show", fn ->
      role = GetRole.call!(id, current_user(conn), preload: [:permissions, :users])

      render(conn, "show.html", role: role)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "roles:update", fn ->
      role = GetRole.call(id, current_user(conn), preload: @preload)
      changeset = Role.changeset(role)
      permissions = ListPermissions.call(current_user(conn))

      render(conn, "edit.html", changeset: changeset, permissions: permissions, role: role)
    end)
  end

  def update(conn, %{"id" => id, "role" => params}) do
    authorize(conn, "roles:update", fn ->
      params = Map.put_new(params, "permissions", [])

      case UpdateRole.call(id, params, current_user(conn)) do
        {:ok, role} ->
          conn
          |> put_flash(:info, "Role updated successfully.")
          |> redirect(to: Routes.role_path(conn, :show, role))

        {:error, %Ecto.Changeset{} = changeset} ->
          role = GetRole.call(id, current_user(conn), preload: @preload)
          permissions = ListPermissions.call(current_user(conn))

          render(conn, "edit.html", changeset: changeset, permissions: permissions, role: role)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "roles:delete", fn ->
      {:ok, _role} = DeleteRole.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Role deleted successfully.")
      |> redirect(to: Routes.role_path(conn, :index))
    end)
  end
end
