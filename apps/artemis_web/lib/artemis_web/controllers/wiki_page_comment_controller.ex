defmodule ArtemisWeb.WikiPageCommentController do
  use ArtemisWeb, :controller

  alias Artemis.Comment
  alias Artemis.CreateComment
  alias Artemis.GetComment
  alias Artemis.GetWikiPage
  alias Artemis.DeleteComment
  alias Artemis.ListComments
  alias Artemis.UpdateComment

  @preload []

  def create(conn, %{"comment" => params, "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:create:comments", fn () ->
      wiki_page = GetWikiPage.call!(wiki_page_id, current_user(conn))
      user = current_user(conn)
      params = params
        |> Map.put("user_id", user.id)
        |> Map.put("wiki_pages", [%{id: wiki_page.id}])

      case CreateComment.call(params, user) do
        {:ok, _comment} ->
          conn
          |> put_flash(:info, "Comment created successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = comment_changeset} ->
          comments = ListComments.call(%{filters: %{wiki_page_id: wiki_page.id}}, current_user(conn))

          conn
          |> put_view(ArtemisWeb.WikiPageView)
          |> render(:show, comment_changeset: comment_changeset, comments: comments, wiki_page: wiki_page)
      end
    end)
  end

  def edit(conn, %{"id" => id, "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:update:comments", fn () ->
      wiki_page = GetWikiPage.call(wiki_page_id, current_user(conn))
      comment = GetComment.call(id, current_user(conn), preload: @preload)
      changeset = Comment.changeset(comment)

      render(conn, "edit.html", changeset: changeset, comment: comment, wiki_page: wiki_page)
    end)
  end

  def update(conn, %{"comment" => params, "id" => id, "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:update:comments", fn () ->
      user = current_user(conn)
      wiki_page = GetWikiPage.call!(wiki_page_id, user)
      params = params
        |> Map.put("user_id", user.id)
        |> Map.put("wiki_pages", [%{id: wiki_page.id}])

      case UpdateComment.call(id, params, user) do
        {:ok, _comment} ->
          conn
          |> put_flash(:info, "Comment updated successfully.")
          |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))

        {:error, %Ecto.Changeset{} = changeset} ->
          comment = GetComment.call(id, user)

          render(conn, "edit.html", changeset: changeset, comment: comment, wiki_page: wiki_page)
      end
    end)
  end

  def delete(conn, %{"id" => id,  "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:delete:comments", fn () ->
      wiki_page = GetWikiPage.call!(wiki_page_id, current_user(conn))
      {:ok, _comment} = DeleteComment.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Comment deleted successfully.")
      |> redirect(to: Routes.wiki_page_path(conn, :show, wiki_page))
    end)
  end
end
