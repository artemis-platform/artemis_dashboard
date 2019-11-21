defmodule ArtemisWeb.TagController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

  alias Artemis.CreateTag
  alias Artemis.Tag
  alias Artemis.DeleteTag
  alias Artemis.GetTag
  alias Artemis.ListTags
  alias Artemis.UpdateTag

  @preload []

  def index(conn, params) do
    authorize(conn, "tags:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      tags = ListTags.call(params, user)

      assigns = [
        tags: tags
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "tags:create", fn ->
      tag = %Tag{}
      changeset = Tag.changeset(tag)

      render(conn, "new.html", changeset: changeset, tag: tag)
    end)
  end

  def create(conn, %{"tag" => params}) do
    authorize(conn, "tags:create", fn ->
      case CreateTag.call(params, current_user(conn)) do
        {:ok, tag} ->
          conn
          |> put_flash(:info, "Tag created successfully.")
          |> redirect(to: Routes.tag_path(conn, :show, tag))

        {:error, %Ecto.Changeset{} = changeset} ->
          tag = %Tag{}

          render(conn, "new.html", changeset: changeset, tag: tag)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "tags:show", fn ->
      tag = GetTag.call!(id, current_user(conn))

      render(conn, "show.html", tag: tag)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "tags:update", fn ->
      tag = GetTag.call(id, current_user(conn), preload: @preload)
      changeset = Tag.changeset(tag)

      render(conn, "edit.html", changeset: changeset, tag: tag)
    end)
  end

  def update(conn, %{"id" => id, "tag" => params}) do
    authorize(conn, "tags:update", fn ->
      case UpdateTag.call(id, params, current_user(conn)) do
        {:ok, tag} ->
          conn
          |> put_flash(:info, "Tag updated successfully.")
          |> redirect(to: Routes.tag_path(conn, :show, tag))

        {:error, %Ecto.Changeset{} = changeset} ->
          tag = GetTag.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, tag: tag)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "tags:delete", fn ->
      {:ok, _tag} = DeleteTag.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Tag deleted successfully.")
      |> redirect(to: Routes.tag_path(conn, :index))
    end)
  end

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "tags:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.tag_path/3,
        resource_type: "Tag"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "tags:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "tags:show", fn ->
      tag_id = Map.get(params, "tag_id")
      tag = GetTag.call!(tag_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.tag_event_log_path/4,
        resource_id: tag_id,
        resource_type: "Tag"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:tag, tag)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "tags:show", fn ->
      tag_id = Map.get(params, "tag_id")
      tag = GetTag.call!(tag_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        tag: tag,
        event_log: event_log
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
