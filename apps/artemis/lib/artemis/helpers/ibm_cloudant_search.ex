defmodule Artemis.Helpers.IBMCloudantSearch do
  @doc """
  Return a cloudant compatible timestamp
  """
  def get_cloudant_timestamp_range(units, duration) do
    precision_lookup = [
      minutes: 16,
      hours: 13,
      days: 10,
      months: 7,
      years: 4
    ]

    precision = Keyword.fetch!(precision_lookup, units)

    past = Timex.shift(Timex.now(), [{units, duration}])
    past_iso = DateTime.to_iso8601(past)
    past_timestamp = String.slice(past_iso, 0, precision)

    now = Timex.now()
    now_iso = DateTime.to_iso8601(now)
    now_timestamp = String.slice(now_iso, 0, precision)

    [past_timestamp, now_timestamp]
  end

  @doc """
  Update search param to match Cloudant format. Takes a series of document keys
  and appends the query to each one. For example:

    params = %{"query" => "hello worl"}
    keys = [:name, :uuid]

  Returns:

    %{"query" => "(default:hello AND default:worl*) OR (name:hello AND name:worl*) OR (uuid:hello AND uuid:worl*)"}

  Note: Requires a `text` type search index with the same keys to already exist
  on database.
  """
  def add_search_param(params, keys, options \\ [])

  def add_search_param(%{"query" => ""} = params, _keys, _options), do: params

  def add_search_param(%{"query" => query_param} = params, keys, options) do
    exact_search? = String.contains?(query_param, [":", " AND ", " NOT ", " OR "])

    case exact_search? do
      true -> params
      false -> Map.put(params, "query", wildcard_search(query_param, keys, options))
    end
  end

  def add_search_param(params, _keys, _options), do: params

  def wildcard_search(query_params, keys, options) do
    query_params
    |> wildcard_search_string(keys)
    |> maybe_add_search_prefix(options)
  end

  defp wildcard_search_string(query, keys) do
    wildcard_query =
      case String.contains?(query, "*") do
        true -> query
        false -> query <> "*"
      end

    words = String.split(wildcard_query)

    keys_with_default =
      case Enum.member?(keys, :default) do
        true -> keys
        false -> [:default | keys]
      end

    key_sections =
      Enum.map(keys_with_default, fn key ->
        key = if is_tuple(key), do: elem(key, 0), else: key

        tokens = Enum.map(words, &"#{key}:#{&1}")
        joined = Enum.join(tokens, " AND ")

        case length(tokens) > 1 do
          true -> "(#{joined})"
          false -> joined
        end
      end)

    Enum.join(key_sections, " OR ")
  end

  defp maybe_add_search_prefix(query_string, id_prefix: id_prefix) do
    "_id: #{id_prefix}* AND (#{query_string})"
  end

  defp maybe_add_search_prefix(query_string, _options), do: query_string
end
