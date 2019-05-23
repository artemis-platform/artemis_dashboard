defmodule Artemis.UpdateWikiPage do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.CreateWikiRevision
  alias Artemis.Helpers.Markdown
  alias Artemis.Repo
  alias Artemis.WikiPage

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating wiki page")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      id
      |> get_record
      |> update_record(params)
      |> create_wiki_revision(user)
      |> update_associations(params)
      |> Event.broadcast("wiki-page:updated", user)
    end)
  end

  def get_record(record) when is_map(record), do: record
  def get_record(id), do: Repo.get(WikiPage, id)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    params = update_params(record, params)

    record
    |> WikiPage.changeset(params)
    |> Repo.update()
  end

  defp update_params(record, params) do
    params = Artemis.Helpers.keys_to_strings(params)

    html =
      case Map.get(params, "body") do
        nil -> nil
        body -> Markdown.to_html!(body)
      end

    slug =
      case Map.get(params, "title", record.title) do
        nil -> nil
        title -> Artemis.Helpers.generate_slug(title)
      end

    params
    |> Map.put("body_html", html)
    |> Map.put("slug", slug)
  end

  defp create_wiki_revision({:ok, record}, user) do
    params =
      record
      |> Map.from_struct()
      |> Map.put(:wiki_page_id, record.id)

    case CreateWikiRevision.call(params, user) do
      {:ok, _} -> {:ok, record}
      error -> error
    end
  end

  defp create_wiki_revision(error, _user), do: error
end
