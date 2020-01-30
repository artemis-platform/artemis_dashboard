defmodule ArtemisWeb.SystemTaskController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.system_task_path/3,
    permission: "system-tasks:list",
    resource_type: "SystemTask"

  alias Artemis.SystemTask

  # TODO: in context, broadcast system task event
  # TODO: should this be liveview, so the task can take as long as needed?
  @available_system_tasks []

  def index(conn, params) do
    authorize(conn, "system-tasks:list", fn ->
      assigns = [
        available_system_tasks: @available_system_tasks
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, params) do
    authorize(conn, "system-tasks:create", fn ->
      changeset = SystemTask.changeset(%SystemTask{}, params)

      assigns = [
        available_system_tasks: @available_system_tasks,
        changeset: changeset
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"system_task" => params}) do
    authorize(conn, "system-tasks:create", fn ->
      # TODO case CreateSystemTask.call(params, current_user(conn)) do
      case {:ok, params} do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Successfully Submitted System Task")
          |> redirect(to: Routes.system_task_path(conn, :index))

        {:error, %Ecto.Changeset{} = changeset} ->
          assigns = [
            available_system_tasks: @available_system_tasks,
            changeset: changeset
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end
end
