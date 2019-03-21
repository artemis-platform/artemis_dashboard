defmodule ArtemisWeb.WikiPageController do
  use ArtemisWeb, :controller

  alias Artemis.CreateWikiPage
  alias Artemis.DeleteWikiPage
  alias Artemis.GetWikiPage
  alias Artemis.ListWikiPages
  alias Artemis.UpdateWikiPage
  alias Artemis.WikiPage

  @preload []

  def index(conn, params) do
    authorize(conn, "wiki-pages:list", fn () ->
      params = Map.put(params, :paginate, true)
      wiki_pages = ListWikiPages.call(params, current_user(conn))

      render(conn, "index.html", wiki_pages: wiki_pages)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "wiki-pages:create", fn () ->
      wiki_page = %WikiPage{}
      changeset = WikiPage.changeset(wiki_page)

      render(conn, "new.html", changeset: changeset, wiki_page: wiki_page)
    end)
  end

  def create(conn, %{"wiki_page" => params}) do
    authorize(conn, "wiki-pages:create", fn () ->
      case CreateWikiPage.call(params, current_user(conn)) do
        {:ok, wiki_page} ->
          conn
          |> put_flash(:info, "Page created successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          wiki_page = %WikiPage{}

          render(conn, "new.html", changeset: changeset, wiki_page: wiki_page)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:show", fn () ->
      wiki_page = GetWikiPage.call!(id, current_user(conn))

      render(conn, "show.html", wiki_page: wiki_page)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:update", fn () ->
      wiki_page = GetWikiPage.call(id, current_user(conn), preload: @preload)
      changeset = WikiPage.changeset(wiki_page)

      render(conn, "edit.html", changeset: changeset, wiki_page: wiki_page)
    end)
  end

  def update(conn, %{"id" => id, "wiki_page" => params}) do
    authorize(conn, "wiki-pages:update", fn () ->
      case UpdateWikiPage.call(id, params, current_user(conn)) do
        {:ok, wiki_page} ->
          conn
          |> put_flash(:info, "Page updated successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          wiki_page = GetWikiPage.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, wiki_page: wiki_page)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:delete", fn () ->
      {:ok, _wiki_page} = DeleteWikiPage.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Page deleted successfully.")
      |> redirect(to: Routes.wiki_page_path(conn, :index))
    end)
  end
end
