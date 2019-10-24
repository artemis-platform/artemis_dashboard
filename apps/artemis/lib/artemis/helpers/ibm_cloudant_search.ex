defmodule Artemis.Helpers.IBMCloudantSearch do
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
  def add_search_param(%{"query" => ""} = params, _keys), do: params

  def add_search_param(%{"query" => query} = params, keys) do
    exact_search? = String.contains?(query, [":", " AND ", " NOT ", " OR "])

    case exact_search? do
      true -> params
      false -> Map.put(params, "query", wildcard_search_query(query, keys))
    end
  end

  def add_search_param(params, _keys), do: params

  defp wildcard_search_query(query, keys) do
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
end
