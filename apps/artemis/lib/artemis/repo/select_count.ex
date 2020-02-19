defmodule Artemis.Repo.SelectCount do
  import Ecto.Query

  @doc """
  Return the aggregate COUNT() of matches in the query
  """
  def select_count(query, %{"count" => true}) do
    query
    |> exclude(:preload)
    |> exclude(:order_by)
    |> select([q], %{count: count(q.id)})
  end

  def select_count(query, _params), do: query
end
