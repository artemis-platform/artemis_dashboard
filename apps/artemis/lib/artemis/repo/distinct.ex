defmodule Artemis.Repo.Distinct do
  import Ecto.Query

  @doc """
  Convert the `distinct` param to distinct clause
  """
  def distinct_query(query, params, options \\ [])

  def distinct_query(query, %{"distinct" => field} = params, options) when is_bitstring(field) do
    schema = if is_map(query), do: elem(query.from.source, 1), else: query
    allow = schema.__schema__(:fields)

    params =
      case Artemis.Helpers.list_to_atoms(field, allow: allow) do
        nil -> Map.delete(params, "distinct")
        as_atom -> Map.put(params, "distinct", as_atom)
      end

    distinct_query(query, params, options)
  end

  def distinct_query(query, %{"distinct" => value}, _options) do
    query
    |> exclude(:distinct)
    |> distinct(^value)
  end

  def distinct_query(query, params, [default: default] = options) do
    updated_params = Map.put(params, "distinct", default)
    updated_options = Keyword.delete(options, :default)

    distinct_query(query, updated_params, updated_options)
  end

  def distinct_query(query, _params, _options), do: query
end
