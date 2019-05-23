defmodule Artemis.ListComments do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Comment
  alias Artemis.Repo

  @default_order "-inserted_at"
  @default_page_size 25
  @default_preload [:user]

  def call(params \\ %{}, user) do
    params = default_params(params)

    Comment
    |> distinct(true)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> search_filter(params)
    |> order_query(params)
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

  defp filter(query, "user_id", value), do: where(query, [c], c.user_id in ^split(value))

  defp filter(query, "wiki_page_id", value) do
    query
    |> join(:left, [comments], wiki_pages in assoc(comments, :wiki_pages))
    |> where([..., wp], wp.id in ^split(value))
  end

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
