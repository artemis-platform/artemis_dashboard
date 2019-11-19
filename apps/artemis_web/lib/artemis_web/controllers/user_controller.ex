defmodule ArtemisWeb.UserController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.BulkActions
  use ArtemisWeb.Controller.Behaviour.EventLogs

  alias Artemis.CreateUser
  alias Artemis.User
  alias Artemis.DeleteUser
  alias Artemis.GetUser
  alias Artemis.ListRoles
  alias Artemis.ListUsers
  alias Artemis.UpdateUser

  @preload [:user_roles]

  def index(conn, params) do
    authorize(conn, "users:list", fn ->
      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, [:roles])

      users = ListUsers.call(params, current_user(conn))

      render(conn, "index.html", users: users)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "users:create", fn ->
      user = %User{user_roles: []}
      changeset = User.changeset(user)
      roles = ListRoles.call(current_user(conn))

      render(conn, "new.html", changeset: changeset, roles: roles, user: user)
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

          render(conn, "new.html", changeset: changeset, roles: roles, user: user)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "users:show", fn ->
      user = GetUser.call!(id, current_user(conn), preload: [:permissions, :roles])

      render(conn, "show.html", user: user)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "users:update", fn ->
      user = GetUser.call(id, current_user(conn), preload: @preload)
      changeset = User.changeset(user)
      roles = ListRoles.call(current_user(conn))

      render(conn, "edit.html", changeset: changeset, roles: roles, user: user)
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

          render(conn, "edit.html", changeset: changeset, roles: roles, user: user)
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

  # Callbacks - Bulk Actions

  def index_bulk_actions(conn, params) do
    authorize(conn, "users:list", fn ->
      ids = Map.get(params, "ids") || []
      key = Map.get(params, "bulk_action")
      user = current_user(conn)
      return_path = Map.get(params, "return_path", Routes.user_path(conn, :index))

      bulk_action = ArtemisWeb.UserView.get_bulk_action(key, user)
      result = bulk_action.(ids, [params, user])
      total_errors = length(result.errors)

      case total_errors == 0 do
        true ->
          conn
          |> put_flash(:info, "Successfully completed bulk #{key} action on #{length(result.data)} records")
          |> redirect(to: return_path)

        false ->
          message = "Error completing bulk #{key} action. Failed on #{total_errors} of #{length(ids)} records."

          conn
          |> put_flash(:error, message)
          |> redirect(to: return_path)
      end
    end)
  end

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "users:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.user_path/3,
        resource_type: "User"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "users:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "users:show", fn ->
      user_id = Map.get(params, "user_id")
      user = GetUser.call!(user_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.user_event_log_path/4,
        resource_id: user_id,
        resource_type: "User"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:user, user)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "users:show", fn ->
      user_id = Map.get(params, "user_id")
      user = GetUser.call!(user_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        user: user,
        event_log: event_log
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
