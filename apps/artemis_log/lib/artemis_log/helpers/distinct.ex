defmodule ArtemisLog.Helpers.Distinct do
  import Ecto.Query

  def distinct_query(query, %{"distinct" => value}) when is_bitstring(value) do
    distinct(query, ^String.to_atom(value))
  end

  def distinct_query(query, %{"distinct" => value}), do: distinct(query, ^value)
  def distinct_query(query, _), do: query
end
