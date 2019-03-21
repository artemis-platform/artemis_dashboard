defmodule ArtemisWeb.WikiRevisionController do
  use ArtemisWeb, :controller

  alias Artemis.DeleteWikiRevision
  alias Artemis.GetWikiPage
  alias Artemis.GetWikiRevision
  alias Artemis.ListWikiRevisions

  def index(conn, params) do
    authorize(conn, "wiki-revisions:list", fn () ->
      params = Map.put(params, :paginate, true)
      wiki_page = get_wiki_page(conn, params)
      wiki_revisions = ListWikiRevisions.call(params, current_user(conn))

      render(conn, "index.html", wiki_page: wiki_page, wiki_revisions: wiki_revisions)
    end)
  end

  def show(conn, params) do
    authorize(conn, "wiki-revisions:show", fn () ->
      wiki_page = get_wiki_page(conn, params)
      wiki_revision = params
        |> Map.get("id")
        |> GetWikiRevision.call!(current_user(conn))

      render(conn, "show.html", wiki_page: wiki_page, wiki_revision: wiki_revision)
    end)
  end

  def delete(conn, params) do
    authorize(conn, "wiki-revisions:delete", fn () ->
      wiki_page = get_wiki_page(conn, params)

      {:ok, _wiki_revision} = params
        |> Map.get("id")
        |> DeleteWikiRevision.call(current_user(conn))

      conn
      |> put_flash(:info, "Revision deleted successfully.")
      |> redirect(to: Routes.wiki_page_wiki_revision_path(conn, :index, wiki_page))
    end)
  end

  # Helpers

  defp get_wiki_page(conn, params) do
    params
    |> Map.get("wiki_page_id")
    |> GetWikiPage.call(current_user(conn))
  end
end
