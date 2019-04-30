defmodule ArtemisWeb.WikiPageTagController do
  use ArtemisWeb, :controller

  alias Artemis.GetWikiPage
  alias Artemis.UpdateWikiPage

  def update(conn, %{"wiki_page" => params, "wiki_page_id" => wiki_page_id}) do
    authorize(conn, "wiki-pages:update:tags", fn () ->
      user = current_user(conn)
      wiki_page = GetWikiPage.call!(wiki_page_id, user)
      params = wiki_page
        |> Map.from_struct
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

  # Helpers
  
  @doc """
  Returns a list of tag params. Will return the ID for existing tags or valid
  params for creating a new tag.
  """
  def tag_params(%{"tags" => names}, type, user), do: tag_params(names, type, user)
  def tag_params(names, type, user) when is_list(names) do
    existing = existing_tags(type, user)

    Enum.map(names, fn (name) ->
      case Map.get(existing, name) do
        nil -> Artemis.GenerateTagParams.call(%{name: name, type: type})
        id -> %{id: id}
      end
    end)
  end
  def tag_params(_, _, _), do: []

  defp existing_tags(type, user) do
    filters = %{type: type}
    params = %{filters: filters}
    tags = Artemis.ListTags.call(params, user)

    Enum.reduce(tags, %{}, fn (tag, acc) ->
      Map.put(acc, tag.name, tag.id)
    end)
  end
end
