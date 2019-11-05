defmodule ArtemisWeb.RoleController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

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
      params = Map.put(params, :paginate, true)
      roles = ListRoles.call(params, current_user(conn))

      render(conn, "index.html", roles: roles)
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

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "roles:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.role_path/3,
        resource_type: "Role"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "roles:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "roles:show", fn ->
      role_id = Map.get(params, "role_id")
      role = GetRole.call!(role_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.role_event_log_path/4,
        resource_id: role_id,
        resource_type: "Role"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:role, role)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "roles:show", fn ->
      role_id = Map.get(params, "role_id")
      role = GetRole.call!(role_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        event_log: event_log,
        role: role
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
