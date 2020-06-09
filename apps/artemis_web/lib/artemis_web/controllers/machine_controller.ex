defmodule ArtemisWeb.MachineController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.MachineView.available_bulk_actions(),
    path: &Routes.machine_path(&1, :index),
    permission: "machines:list"

  use ArtemisWeb.Controller.CommentsShow,
    path: &Routes.machine_path/3,
    permission: "machines:show",
    resource_getter: &Artemis.GetMachine.call!/2,
    resource_id_key: "machine_id",
    resource_type: "Machine"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.machine_path/3,
    permission: "machines:list",
    resource_type: "Machine"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.machine_event_log_path/4,
    permission: "machines:show",
    resource_getter: &Artemis.GetMachine.call!/2,
    resource_id: "machine_id",
    resource_type: "Machine",
    resource_variable: :machine

  alias Artemis.CreateMachine
  alias Artemis.Machine
  alias Artemis.DeleteMachine
  alias Artemis.GetMachine
  alias Artemis.ListClouds
  alias Artemis.ListDataCenters
  alias Artemis.ListMachines
  alias Artemis.UpdateMachine

  @preload [:cloud, :customer, :data_center]

  def index(conn, params) do
    authorize(conn, "machines:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, @preload)

      clouds = ListClouds.call(user)
      data_centers = ListDataCenters.call(user)
      machines = ListMachines.call(params, user)
      allowed_bulk_actions = ArtemisWeb.MachineView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        clouds: clouds,
        data_centers: data_centers,
        machines: machines
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "machines:create", fn ->
      machine = %Machine{}
      changeset = Machine.changeset(machine)

      render(conn, "new.html", changeset: changeset, machine: machine)
    end)
  end

  def create(conn, %{"machine" => params}) do
    authorize(conn, "machines:create", fn ->
      case CreateMachine.call(params, current_user(conn)) do
        {:ok, machine} ->
          conn
          |> put_flash(:info, "Machine created successfully.")
          |> redirect(to: Routes.machine_path(conn, :show, machine))

        {:error, %Ecto.Changeset{} = changeset} ->
          machine = %Machine{}

          render(conn, "new.html", changeset: changeset, machine: machine)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "machines:show", fn ->
      machine = GetMachine.call!(id, current_user(conn), preload: @preload)

      render(conn, "show.html", machine: machine)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "machines:update", fn ->
      machine = GetMachine.call(id, current_user(conn), preload: @preload)
      changeset = Machine.changeset(machine)

      render(conn, "edit.html", changeset: changeset, machine: machine)
    end)
  end

  def update(conn, %{"id" => id, "machine" => params}) do
    authorize(conn, "machines:update", fn ->
      case UpdateMachine.call(id, params, current_user(conn)) do
        {:ok, machine} ->
          conn
          |> put_flash(:info, "Machine updated successfully.")
          |> redirect(to: Routes.machine_path(conn, :show, machine))

        {:error, %Ecto.Changeset{} = changeset} ->
          machine = GetMachine.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, machine: machine)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "machines:delete", fn ->
      {:ok, _machine} = DeleteMachine.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Machine deleted successfully.")
      |> redirect(to: Routes.machine_path(conn, :index))
    end)
  end
end
