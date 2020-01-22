defmodule ArtemisWeb.DataCenterController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.DataCenterView.available_bulk_actions(),
    path: &Routes.data_center_path(&1, :index),
    permission: "data-centers:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.data_center_path/3,
    permission: "data-centers:list",
    resource_type: "DataCenter"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.data_center_event_log_path/4,
    permission: "data-centers:show",
    resource_getter: &Artemis.GetDataCenter.call!/2,
    resource_id: "data_center_id",
    resource_type: "DataCenter",
    resource_variable: :data_center

  alias Artemis.CreateDataCenter
  alias Artemis.DataCenter
  alias Artemis.DeleteDataCenter
  alias Artemis.GetDataCenter
  alias Artemis.ListDataCenters
  alias Artemis.UpdateDataCenter

  @preload []

  def index(conn, params) do
    authorize(conn, "data-centers:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      data_centers = ListDataCenters.call(params, user)
      allowed_bulk_actions = ArtemisWeb.DataCenterView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        data_centers: data_centers
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "data-centers:create", fn ->
      data_center = %DataCenter{}
      changeset = DataCenter.changeset(data_center)

      render(conn, "new.html", changeset: changeset, data_center: data_center)
    end)
  end

  def create(conn, %{"data_center" => params}) do
    authorize(conn, "data-centers:create", fn ->
      case CreateDataCenter.call(params, current_user(conn)) do
        {:ok, data_center} ->
          conn
          |> put_flash(:info, "Data Center created successfully.")
          |> redirect(to: Routes.data_center_path(conn, :show, data_center))

        {:error, %Ecto.Changeset{} = changeset} ->
          data_center = %DataCenter{}

          render(conn, "new.html", changeset: changeset, data_center: data_center)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "data-centers:show", fn ->
      data_center = GetDataCenter.call!(id, current_user(conn))

      render(conn, "show.html", data_center: data_center)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "data-centers:update", fn ->
      data_center = GetDataCenter.call(id, current_user(conn), preload: @preload)
      changeset = DataCenter.changeset(data_center)

      render(conn, "edit.html", changeset: changeset, data_center: data_center)
    end)
  end

  def update(conn, %{"id" => id, "data_center" => params}) do
    authorize(conn, "data-centers:update", fn ->
      case UpdateDataCenter.call(id, params, current_user(conn)) do
        {:ok, data_center} ->
          conn
          |> put_flash(:info, "Data Center updated successfully.")
          |> redirect(to: Routes.data_center_path(conn, :show, data_center))

        {:error, %Ecto.Changeset{} = changeset} ->
          data_center = GetDataCenter.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, data_center: data_center)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "data-centers:delete", fn ->
      {:ok, _data_center} = DeleteDataCenter.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Data Center deleted successfully.")
      |> redirect(to: Routes.data_center_path(conn, :index))
    end)
  end
end
