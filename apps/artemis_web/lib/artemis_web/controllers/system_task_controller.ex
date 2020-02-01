defmodule ArtemisWeb.SystemTaskController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.system_task_path/3,
    permission: "system-tasks:list",
    resource_type: "SystemTask"

  alias Artemis.CreateSystemTask
  alias Artemis.SystemTask

  def index(conn, _params) do
    authorize(conn, "system-tasks:list", fn ->
      user = current_user(conn)

      assigns = [
        system_tasks: get_allowed_system_tasks(user),
        system_task_type_options: get_allowed_system_task_type_options(user)
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, params) do
    authorize(conn, "system-tasks:create", fn ->
      user = current_user(conn)
      changeset = SystemTask.changeset(%SystemTask{}, params)

      assigns = [
        changeset: changeset,
        system_task_type_options: get_allowed_system_task_type_options(user)
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"system_task" => params}) do
    authorize(conn, "system-tasks:create", fn ->
      user = current_user(conn)

      case CreateSystemTask.call(params, user) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Successfully Submitted System Task")
          |> redirect(to: Routes.system_task_path(conn, :index))

        {:error, %Ecto.Changeset{} = changeset} ->
          assigns = [
            changeset: changeset,
            system_task_type_options: get_allowed_system_task_type_options(user)
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end

  # Helpers

  defp get_allowed_system_tasks(user) do
    SystemTask.allowed_system_tasks()
    |> Enum.reduce([], fn system_task, acc ->
      allowed? = system_task.verify.(user)

      case allowed? do
        true -> [system_task | acc]
        false -> acc
      end
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp get_allowed_system_task_type_options(user) do
    Enum.reduce(SystemTask.allowed_system_tasks(), [], fn system_task, acc ->
      allowed? = system_task.verify.(user)
      option = [key: system_task.name, value: system_task.type]

      case allowed? do
        true -> [option | acc]
        false -> acc
      end
    end)
  end
end
