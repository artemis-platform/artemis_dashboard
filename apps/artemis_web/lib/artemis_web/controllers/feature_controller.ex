defmodule ArtemisWeb.FeatureController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

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

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "features:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.feature_path/3,
        resource_type: "Feature"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "features:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "features:show", fn ->
      feature_id = Map.get(params, "feature_id")
      feature = GetFeature.call!(feature_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.feature_event_log_path/4,
        resource_id: feature_id,
        resource_type: "Feature"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:feature, feature)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "features:show", fn ->
      feature_id = Map.get(params, "feature_id")
      feature = GetFeature.call!(feature_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        event_log: event_log,
        feature: feature
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
