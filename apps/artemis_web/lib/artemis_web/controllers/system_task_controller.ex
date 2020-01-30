defmodule ArtemisWeb.SystemTaskController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.system_task_path/3,
    permission: "system-tasks:list",
    resource_type: "SystemTask"

  # TODO: in context, broadcast system task event
  # TODO: should this be liveview, so the task can take as long as needed?
  @available_system_tasks [

  ]

  def index(conn, params) do
    authorize(conn, "system-tasks:list", fn ->
      # user = current_user(conn)
      # system_tasks = ListSystemTasks.call(params, user)
      available_system_tasks = []

      assigns = [
        available_system_tasks: @available_system_tasks
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "system-tasks:create", fn ->
      assigns = [
        available_system_tasks: @available_system_tasks
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"system_task" => params}) do
    authorize(conn, "system-tasks:create", fn ->
      # case CreateFeature.call(params, current_user(conn)) do
      #   {:ok, feature} ->
      #     conn
      #     |> put_flash(:info, "Executing System Task.")
      #     |> redirect(to: Routes.system_task_path(conn, :index))

      #   {:error, %Ecto.Changeset{} = changeset} ->
      #     feature = %Feature{}

      #     render(conn, "new.html", changeset: changeset, feature: feature)
      # end
    end)
  end
end
