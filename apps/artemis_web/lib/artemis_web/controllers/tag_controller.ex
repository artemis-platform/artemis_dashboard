defmodule ArtemisWeb.TagController do
  use ArtemisWeb, :controller

  alias Artemis.CreateTag
  alias Artemis.Tag
  alias Artemis.DeleteTag
  alias Artemis.GetTag
  alias Artemis.ListTags
  alias Artemis.UpdateTag

  @preload []

  def index(conn, params) do
    authorize(conn, "tags:list", fn () ->
      params = Map.put(params, :paginate, true)
      tags = ListTags.call(params, current_user(conn))

      render(conn, "index.html", tags: tags)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "tags:create", fn () ->
      tag = %Tag{}
      changeset = Tag.changeset(tag)

      render(conn, "new.html", changeset: changeset, tag: tag)
    end)
  end

  def create(conn, %{"tag" => params}) do
    authorize(conn, "tags:create", fn () ->
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
    authorize(conn, "tags:show", fn () ->
      tag = GetTag.call!(id, current_user(conn))

      render(conn, "show.html", tag: tag)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "tags:update", fn () ->
      tag = GetTag.call(id, current_user(conn), preload: @preload)
      changeset = Tag.changeset(tag)

      render(conn, "edit.html", changeset: changeset, tag: tag)
    end)
  end

  def update(conn, %{"id" => id, "tag" => params}) do
    authorize(conn, "tags:update", fn () ->
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

  def delete(conn, %{"id" => id}) do
    authorize(conn, "tags:delete", fn () ->
      {:ok, _tag} = DeleteTag.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Tag deleted successfully.")
      |> redirect(to: Routes.tag_path(conn, :index))
    end)
  end
end
