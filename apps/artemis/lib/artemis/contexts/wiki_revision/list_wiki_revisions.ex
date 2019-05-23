defmodule Artemis.ListWikiRevisions do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.WikiRevision

  @default_order "-updated_at"
  @default_page_size 25
  @default_preload [:user]

  def call(params \\ %{}, user) do
    params = default_params(params)

    WikiRevision
    |> distinct(true)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
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

  defp filter(query, "wiki_page_id", value), do: where(query, [wr], wr.wiki_page_id in ^split(value))

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
