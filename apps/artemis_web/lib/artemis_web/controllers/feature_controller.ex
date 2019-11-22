defmodule ArtemisWeb.FeatureController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.FeatureView.available_bulk_actions(),
    path: &Routes.feature_path(&1, :index),
    permission: "features:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.feature_path/3,
    permission: "features:list",
    resource_type: "Feature"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.feature_event_log_path/4,
    permission: "features:show",
    resource_getter: &Artemis.GetFeature.call!/2,
    resource_id: "feature_id",
    resource_type: "Feature",
    resource_variable: :feature

  alias Artemis.CreateFeature
  alias Artemis.Feature
  alias Artemis.DeleteFeature
  alias Artemis.GetFeature
  alias Artemis.ListFeatures
  alias Artemis.UpdateFeature

  @preload []

  def index(conn, params) do
    authorize(conn, "features:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      cache = ListFeatures.call_with_cache(params, user)

      assigns = [
        cache: cache,
        features: cache.data
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "features:create", fn ->
      feature = %Feature{}
      changeset = Feature.changeset(feature)

      render(conn, "new.html", changeset: changeset, feature: feature)
    end)
  end

  def create(conn, %{"feature" => params}) do
    authorize(conn, "features:create", fn ->
      case CreateFeature.call(params, current_user(conn)) do
        {:ok, feature} ->
          conn
          |> put_flash(:info, "Feature created successfully.")
          |> redirect(to: Routes.feature_path(conn, :show, feature))

        {:error, %Ecto.Changeset{} = changeset} ->
          feature = %Feature{}

          render(conn, "new.html", changeset: changeset, feature: feature)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "features:show", fn ->
      feature = GetFeature.call!(id, current_user(conn))

      render(conn, "show.html", feature: feature)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "features:update", fn ->
      feature = GetFeature.call(id, current_user(conn), preload: @preload)
      changeset = Feature.changeset(feature)

      render(conn, "edit.html", changeset: changeset, feature: feature)
    end)
  end

  def update(conn, %{"id" => id, "feature" => params}) do
    authorize(conn, "features:update", fn ->
      case UpdateFeature.call(id, params, current_user(conn)) do
        {:ok, feature} ->
          conn
          |> put_flash(:info, "Feature updated successfully.")
          |> redirect(to: Routes.feature_path(conn, :show, feature))

        {:error, %Ecto.Changeset{} = changeset} ->
          feature = GetFeature.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, feature: feature)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "features:delete", fn ->
      {:ok, _feature} = DeleteFeature.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Feature deleted successfully.")
      |> redirect(to: Routes.feature_path(conn, :index))
    end)
  end
end
