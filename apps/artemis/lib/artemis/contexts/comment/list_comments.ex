defmodule Artemis.ListComments do
  use Artemis.Context

  use Artemis.ContextCache,
    cache_reset_on_events: [
      "comment:created",
      "comment:deleted",
      "comment:updated"
    ]

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
    |> distinct_query(params, default: true)
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

  defp filter(query, "resource_id", value) when is_integer(value) do
    filter(query, "resource_id", Integer.to_string(value))
  end

  defp filter(query, "resource_id", value), do: where(query, [c], c.resource_id in ^split(value))
  defp filter(query, "resource_type", value), do: where(query, [c], c.resource_type in ^split(value))
  defp filter(query, "user_id", value), do: where(query, [c], c.user_id in ^split(value))

  defp filter(query, _, _), do: query

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
