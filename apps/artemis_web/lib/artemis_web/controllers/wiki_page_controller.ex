defmodule ArtemisWeb.WikiPageController do
  use ArtemisWeb, :controller

  alias Artemis.Comment
  alias Artemis.CreateWikiPage
  alias Artemis.DeleteWikiPage
  alias Artemis.GetWikiPage
  alias Artemis.ListComments
  alias Artemis.ListTags
  alias Artemis.ListWikiPages
  alias Artemis.UpdateWikiPage
  alias Artemis.WikiPage

  @default_section "General"
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
      sections = get_sections()

      render(conn, "new.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
    end)
  end

  def create(conn, %{"wiki_page" => params}) do
    authorize(conn, "wiki-pages:create", fn () ->
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
    authorize(conn, "wiki-pages:show", fn () ->
      user = current_user(conn)
      wiki_page = GetWikiPage.call!(id, user)
      comments = ListComments.call(%{filters: %{wiki_page_id: id}}, user)
      comment_changeset = Comment.changeset(%Comment{})
      changeset = WikiPage.changeset(wiki_page)
      tags = ListTags.call(%{filters: %{type: "wiki-pages"}}, user)

      render(conn, "show.html", changeset: changeset, comment_changeset: comment_changeset, comments: comments, tags: tags, wiki_page: wiki_page)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "wiki-pages:update", fn () ->
      wiki_page = GetWikiPage.call(id, current_user(conn), preload: @preload)
      changeset = WikiPage.changeset(wiki_page)
      sections = get_sections()

      render(conn, "edit.html", changeset: changeset, sections: sections, wiki_page: wiki_page)
    end)
  end

  def update(conn, %{"id" => id, "wiki_page" => params}) do
    authorize(conn, "wiki-pages:update", fn () ->
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
    authorize(conn, "wiki-pages:delete", fn () ->
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

        [@default_section|omitted]
      false ->
        [@default_section|sections]
    end
  end
end
