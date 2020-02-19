defmodule Artemis.ListWikiPages do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.WikiPage

  @default_order "slug"
  @default_page_size 25
  @default_preload [:user]

  def call(params \\ %{}, user) do
    params = default_params(params)

    WikiPage
    |> distinct(true)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> search_filter(params)
    |> order_query(params)
    |> select_count(params)
    |> get_records(params)
  end

  defp default_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> Map.put_new("order", @default_order)
    |> Map.put_new("page_size", @default_page_size)
    |> Map.put_new("preload", @default_preload)
  end

  defp filter_query(query, %{"filters" => filters}, _user) when is_map(filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter(acc, key, value)
    end)
  end

  defp filter_query(query, _params, _user), do: query

  defp filter(query, "section", value), do: where(query, [wp], wp.section in ^split(value))
  defp filter(query, "slug", value), do: where(query, [wp], wp.slug in ^split(value))

  defp filter(query, "tags", value) do
    query
    |> join(:left, [wiki_pages], tags in assoc(wiki_pages, :tags))
    |> where([..., t], t.slug in ^split(value))
  end

  defp filter(query, "title", value), do: where(query, [wp], wp.title in ^split(value))

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
