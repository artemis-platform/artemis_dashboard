defmodule Artemis.Helpers.Search do
  import Artemis.Helpers
  import Ecto.Query

  @doc """
  Example Usage:
  where(ecto_query, [table], fragment("? @@ ?", table.tsv_search, to_tsquery(^value)))
  """
  defmacro to_tsquery(query) do
    quote do
      fragment("to_tsquery('english', ?)", unquote(query))
    end
  end

  @doc """
  Example Usage:
  order_by(ecto_query, [table], desc: ts_rank_cd(table.tsv_search, to_tsquery(^value)))
  """
  defmacro ts_rank_cd(tsv, query) do
    quote do
      fragment("ts_rank_cd(?, ?)", unquote(tsv), unquote(query))
    end
  end

  def search_filter(ecto_query, %{"query" => search_query}) do
    case present?(search_query) do
      true -> add_search_filters(ecto_query, search_query)
      false -> ecto_query
    end
  end

  def search_filter(ecto_query, _), do: ecto_query

  defp add_search_filters(ecto_query, search_query) do
    values =
      search_query
      |> String.split(" ")
      |> Enum.map(&String.trim(&1))
      |> Enum.reject(&(&1 == ""))

    Enum.reduce(values, ecto_query, &add_search_filter/2)
  end

  defp add_search_filter(value, ecto_query) do
    value = "'#{value}':*"

    where(ecto_query, [table], fragment("? @@ ?", table.tsv_search, to_tsquery(^value)))
  end
end
