defmodule ArtemisWeb.WikiPageController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.CommentsShow,
    path: &Routes.wiki_page_path/3,
    permission: "wiki-pages:show",
    resource_getter: &Artemis.GetWikiPage.call!/2,
    resource_id_key: "wiki_page_id",
    resource_type: "WikiPage"

  alias Artemis.CreateWikiPage
  alias Artemis.DeleteWikiPage
  alias Artemis.GetWikiPage
  alias Artemis.ListWikiPages
  alias Artemis.UpdateWikiPage
  alias Artemis.WikiPage

  @default_section "General"
  @preload []

  def index(conn, params) do
    authorize(conn, "wiki-pages:list", fn ->
      user = current_user(conn)
      params = Map.put(params, :paginate, true)
      tags = get_tags("wiki-pages", user)
      wiki_pages = ListWikiPages.call(params, user)

      render(conn, "index.html", tags: tags, wiki_pages: wiki_pages)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "wiki-pages:create", fn ->
      wiki_page = %WikiPage{}
      changeset = WikiPage.changeset(wiki_page)
      sections = get_sections()

      render(conn, "new.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
    end)
  end

  def create(conn, %{"wiki_page" => params}) do
    authorize(conn, "wiki-pages:create", fn ->
      user = current_user(conn)
      params = Map.put(params, "user_id", user.id)

      case CreateWikiPage.call(params, user) do
        {:ok, wiki_page} ->
          conn
          |> put_flash(:info, "Page created successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          wiki_page = %WikiPage{}
          sections = get_sections()

          render(conn, "new.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:show", fn ->
      user = current_user(conn)
      wiki_page = GetWikiPage.call!(id, user)
      tags = get_tags("wiki-pages", user)
      tags_changeset = WikiPage.changeset(wiki_page)

      render(conn, "show.html",
        tags: tags,
        tags_changeset: tags_changeset,
        wiki_page: wiki_page
      )
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:update", fn ->
      wiki_page = GetWikiPage.call(id, current_user(conn), preload: @preload)
      changeset = WikiPage.changeset(wiki_page)
      sections = get_sections()

      render(conn, "edit.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
    end)
  end

  def update(conn, %{"id" => id, "wiki_page" => params}) do
    authorize(conn, "wiki-pages:update", fn ->
      user = current_user(conn)
      params = Map.put(params, "user_id", user.id)

      case UpdateWikiPage.call(id, params, user) do
        {:ok, wiki_page} ->
          conn
          |> put_flash(:info, "Page updated successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          wiki_page = GetWikiPage.call(id, current_user(conn), preload: @preload)
          sections = get_sections()

          render(conn, "edit.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:delete", fn ->
      {:ok, _wiki_page} = DeleteWikiPage.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Page deleted successfully.")
      |> redirect(to: Routes.wiki_page_path(conn, :index))
    end)
  end

  # Helpers

  defp get_sections do
    sections = WikiPage.unique_values_for(:section)

    case Enum.member?(sections, @default_section) do
      true ->
        omitted = List.delete(sections, @default_section)

        [@default_section | omitted]

      false ->
        [@default_section | sections]
    end
  end
end
