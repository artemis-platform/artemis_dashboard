defmodule ArtemisWeb.PermissionController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

  alias Artemis.CreatePermission
  alias Artemis.Permission
  alias Artemis.DeletePermission
  alias Artemis.GetPermission
  alias Artemis.ListPermissions
  alias Artemis.UpdatePermission

  @preload []

  def index(conn, params) do
    authorize(conn, "permissions:list", fn ->
      params = Map.put(params, :paginate, true)
      permissions = ListPermissions.call(params, current_user(conn))

      render_format(conn, "index", permissions: permissions)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "permissions:create", fn ->
      permission = %Permission{}
      changeset = Permission.changeset(permission)

      render(conn, "new.html", changeset: changeset, permission: permission)
    end)
  end

  def create(conn, %{"permission" => params}) do
    authorize(conn, "permissions:create", fn ->
      case CreatePermission.call(params, current_user(conn)) do
        {:ok, permission} ->
          conn
          |> put_flash(:info, "Permission created successfully.")
          |> redirect(to: Routes.permission_path(conn, :show, permission))

        {:error, %Ecto.Changeset{} = changeset} ->
          permission = %Permission{}

          render(conn, "new.html", changeset: changeset, permission: permission)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "permissions:show", fn ->
      permission = GetPermission.call!(id, current_user(conn))

      render(conn, "show.html", permission: permission)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "permissions:update", fn ->
      permission = GetPermission.call(id, current_user(conn), preload: @preload)
      changeset = Permission.changeset(permission)

      render(conn, "edit.html", changeset: changeset, permission: permission)
    end)
  end

  def update(conn, %{"id" => id, "permission" => params}) do
    authorize(conn, "permissions:update", fn ->
      case UpdatePermission.call(id, params, current_user(conn)) do
        {:ok, permission} ->
          conn
          |> put_flash(:info, "Permission updated successfully.")
          |> redirect(to: Routes.permission_path(conn, :show, permission))

        {:error, %Ecto.Changeset{} = changeset} ->
          permission = GetPermission.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, permission: permission)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    authorize(conn, "permissions:delete", fn ->
      {:ok, _permission} = DeletePermission.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Permission deleted successfully.")
      |> redirect(to: Routes.permission_path(conn, :index))
    end)
  end

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "permissions:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.permission_path/3,
        resource_type: "Permission"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "permissions:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "permissions:show", fn ->
      permission_id = Map.get(params, "permission_id")
      permission = GetPermission.call!(permission_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.permission_event_log_path/4,
        resource_id: permission_id,
        resource_type: "Permission"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:permission, permission)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "permissions:show", fn ->
      permission_id = Map.get(params, "permission_id")
      permission = GetPermission.call!(permission_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        event_log: event_log,
        permission: permission
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
