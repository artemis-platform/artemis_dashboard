defmodule ArtemisWeb.CloudController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.CloudView.available_bulk_actions(),
    path: &Routes.cloud_path(&1, :index),
    permission: "clouds:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.cloud_path/3,
    permission: "clouds:list",
    resource_type: "Cloud"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.cloud_event_log_path/4,
    permission: "clouds:show",
    resource_getter: &Artemis.GetCloud.call!/2,
    resource_id: "cloud_id",
    resource_type: "Cloud",
    resource_variable: :cloud

  alias Artemis.CreateCloud
  alias Artemis.Cloud
  alias Artemis.DeleteCloud
  alias Artemis.GetCloud
  alias Artemis.ListClouds
  alias Artemis.ListMachines
  alias Artemis.UpdateCloud

  @preload [:customer, :data_centers, :machines]

  def index(conn, params) do
    authorize(conn, "clouds:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, @preload)

      clouds = ListClouds.call(params, user)
      allowed_bulk_actions = ArtemisWeb.CloudView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        clouds: clouds
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "clouds:create", fn ->
      cloud = %Cloud{}
      changeset = Cloud.changeset(cloud)

      render(conn, "new.html", changeset: changeset, cloud: cloud)
    end)
  end

  def create(conn, %{"cloud" => params}) do
    authorize(conn, "clouds:create", fn ->
      case CreateCloud.call(params, current_user(conn)) do
        {:ok, cloud} ->
          conn
          |> put_flash(:info, "Cloud created successfully.")
          |> redirect(to: Routes.cloud_path(conn, :show, cloud))

        {:error, %Ecto.Changeset{} = changeset} ->
          cloud = %Cloud{}

          render(conn, "new.html", changeset: changeset, cloud: cloud)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "clouds:show", fn ->
      user = current_user(conn)
      cloud = GetCloud.call!(id, user, preload: @preload)
      associated_machines = list_related_machines(conn, cloud, user)

      assigns = [
        cloud: cloud,
        associated_machines: associated_machines
      ]

      render(conn, "show.html", assigns)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "clouds:update", fn ->
      cloud = GetCloud.call(id, current_user(conn), preload: @preload)
      changeset = Cloud.changeset(cloud)

      render(conn, "edit.html", changeset: changeset, cloud: cloud)
    end)
  end

  def update(conn, %{"id" => id, "cloud" => params}) do
    authorize(conn, "clouds:update", fn ->
      case UpdateCloud.call(id, params, current_user(conn)) do
        {:ok, cloud} ->
          conn
          |> put_flash(:info, "Cloud updated successfully.")
          |> redirect(to: Routes.cloud_path(conn, :show, cloud))

        {:error, %Ecto.Changeset{} = changeset} ->
          cloud = GetCloud.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, cloud: cloud)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "clouds:delete", fn ->
      {:ok, _cloud} = DeleteCloud.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Cloud deleted successfully.")
      |> redirect(to: Routes.cloud_path(conn, :index))
    end)
  end

  # Helpers

  defp list_related_machines(conn, cloud, user) do
    params = %{
      "filters" => %{
        "cloud_id" => cloud.id
      },
      "paginate" => true,
      "preload" => [
        :data_center
      ]
    }

    conn
    |> Map.get(:query_params)
    |> Artemis.Helpers.deep_merge(params)
    |> ListMachines.call(user)
  end
end
