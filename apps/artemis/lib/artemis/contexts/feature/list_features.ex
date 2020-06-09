defmodule Artemis.ListFeatures do
  use Artemis.Context

  use Artemis.ContextCache,
    cache_reset_on_events: [
      "feature:created",
      "feature:deleted",
      "feature:updated"
    ]

  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Feature
  alias Artemis.Repo

  @default_order "slug"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, _user) do
    params = default_params(params)

    Feature
    |> distinct_query(params, default: true)
    |> preload(^Map.get(params, "preload"))
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

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
