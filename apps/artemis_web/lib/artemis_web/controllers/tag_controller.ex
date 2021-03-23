defmodule ArtemisWeb.TagController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.TagView.available_bulk_actions(),
    path: &Routes.tag_path(&1, :index),
    permission: "tags:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.tag_path/3,
    permission: "tags:list",
    resource_type: "Tag"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.tag_event_log_path/4,
    permission: "tags:show",
    resource_getter: &Artemis.GetTag.call!/2,
    resource_id: "tag_id",
    resource_type: "Tag",
    resource_variable: :tag

  alias Artemis.CreateTag
  alias Artemis.Tag
  alias Artemis.DeleteTag
  alias Artemis.GetTag
  alias Artemis.ListTags
  alias Artemis.UpdateTag

  @preload []

  def index(conn, params) do
    authorize(conn, "tags:list", fn ->
      render_with_cache_then_update(conn, params, ArtemisWeb.TagView, "index", fn callback_pid, _assigns ->
        user = current_user(conn)
        params = Map.put(params, :paginate, true)
        tags = ListTags.call_with_cache_then_update(params, user, callback_pid: callback_pid)
        allowed_bulk_actions = ArtemisWeb.TagView.allowed_bulk_actions(user)

        [
          allowed_bulk_actions: allowed_bulk_actions,
          tags: tags
        ]
      end)
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
end
