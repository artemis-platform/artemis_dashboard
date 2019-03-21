defmodule Artemis.CreateWikiPage do
  use Artemis.Context

  alias Artemis.CreateWikiRevision
  alias Artemis.Repo
  alias Artemis.WikiPage

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating wiki page")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn () ->
      params
      |> insert_record()
      |> create_wiki_revision(user)
      |> Event.broadcast("wiki-page:created", user)
    end)
  end

  defp insert_record(params) do
    params = create_params(params)

    %WikiPage{}
    |> WikiPage.changeset(params)
    |> Repo.insert
  end

  defp create_params(params) do
    params = Artemis.Helpers.keys_to_strings(params)
    html = params
      |> Map.get("body", "")
      |> Earmark.as_html!()
    slug = params
      |> Map.get("title", "")
      |> Artemis.Helpers.generate_slug()

    params
    |> Map.put("body_html", html)
    |> Map.put("slug", slug)
  end

  defp create_wiki_revision({:ok, record}, user) do
    params = record
      |> Map.from_struct()
      |> Map.put(:wiki_page_id, record.id)

    case CreateWikiRevision.call(params, user) do
      {:ok, _} -> {:ok, record}
      error -> error
    end
  end
  defp create_wiki_revision(error, _user), do: error
end
