defmodule ArtemisWeb.WikiPageTagController do
  use ArtemisWeb, :controller

  alias Artemis.GetWikiPage
  alias Artemis.UpdateWikiPage

  def update(conn, %{"wiki_page" => params, "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:update:tags", fn ->
      user = current_user(conn)
      wiki_page = GetWikiPage.call!(wiki_page_id, user)

      params =
        wiki_page
        |> Map.from_struct()
        |> Map.put(:tags, tag_params(params, "wiki-pages", user))

      case UpdateWikiPage.call(wiki_page_id, params, user) do
        {:ok, wiki_page} ->
          conn
          |> put_flash(:info, "Tags updated successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "Error updating tags.")
          |> put_view(ArtemisWeb.WikiPageView)
          |> render(:show, changeset: changeset, wiki_page: wiki_page)
      end
    end)
  end
end
