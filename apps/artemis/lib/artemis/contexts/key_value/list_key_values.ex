defmodule Artemis.ListKeyValues do
  use Artemis.Context

  use Artemis.ContextCache,
    cache_reset_on_events: [
      "key-value:created",
      "key-value:deleted",
      "key-value:updated"
    ]

  import Artemis.Helpers.Filter
  import Ecto.Query

  alias Artemis.KeyValue
  alias Artemis.Repo

  @default_order "-updated_at"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, user) do
    params = default_params(params)

    KeyValue
    |> select_query(KeyValue, params)
    |> distinct_query(params, default: false)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> order_query(params)
    |> get_records(params)
    |> maybe_decode_results()
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

  defp filter(query, _key, nil), do: query
  defp filter(query, _key, ""), do: query
  defp filter(query, "expire_at", value), do: where(query, [i], i.expire_at in ^split(value))
  defp filter(query, "expire_at_gt", value), do: where(query, [i], i.expire_at > ^value)
  defp filter(query, "expire_at_gte", value), do: where(query, [i], i.expire_at >= ^value)
  defp filter(query, "expire_at_lt", value), do: where(query, [i], i.expire_at < ^value)
  defp filter(query, "expire_at_lte", value), do: where(query, [i], i.expire_at <= ^value)
  defp filter(query, "id", value), do: where(query, [i], i.id in ^split(value))
  defp filter(query, "key", value), do: where(query, [i], i.key in ^split_and_encode(value))
  defp filter(query, _key, _value), do: query

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)

  # Helpers - Encoding

  defp split_and_encode(value) do
    value
    |> split()
    |> Enum.map(&KeyValue.encode/1)
  end

  # Helpers - Decoding

  defp maybe_decode_results(results) when is_map(results) do
    decoded =
      results
      |> Map.get(:entries)
      |> maybe_decode_results()

    Map.put(results, :entries, decoded)
  end

  defp maybe_decode_results(results) when is_list(results) do
    Enum.map(results, &maybe_decode_result/1)
  end

  defp maybe_decode_results(error), do: error

  defp maybe_decode_result(result) do
    result
    |> maybe_decode_key()
    |> maybe_decode_value()
  end

  defp maybe_decode_key(result) when is_map(result) do
    case Map.get(result, :key) do
      nil -> result
      key -> Map.put(result, :key, KeyValue.decode(key))
    end
  end

  defp maybe_decode_key(result), do: result

  defp maybe_decode_value(result) when is_map(result) do
    case Map.get(result, :value) do
      nil -> result
      value -> Map.put(result, :value, KeyValue.decode(value))
    end
  end

  defp maybe_decode_value(result), do: result
end
