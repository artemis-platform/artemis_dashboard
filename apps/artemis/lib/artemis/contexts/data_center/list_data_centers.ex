defmodule Artemis.ListDataCenters do
  use Artemis.Context

  use Artemis.ContextCache,
    cache_reset_on_events: [
      "data-center:created",
      "data-center:deleted",
      "data-center:updated"
    ]

  import Artemis.Helpers.Filter
  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.DataCenter

  @default_order "slug"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, user) do
    params = default_params(params)

    DataCenter
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

  defp filter(query, "country", value), do: where(query, [i], i.country in ^split(value))
  defp filter(query, "latitude", value), do: where(query, [i], i.latitude in ^split(value))
  defp filter(query, "longitude", value), do: where(query, [i], i.longitude in ^split(value))
  defp filter(query, "name", value), do: where(query, [i], i.name in ^split(value))
  defp filter(query, "slug", value), do: where(query, [i], i.slug in ^split(value))

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
