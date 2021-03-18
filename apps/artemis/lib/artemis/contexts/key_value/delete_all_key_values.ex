defmodule Artemis.DeleteAllKeyValues do
  use Artemis.Context

  import Ecto.Query
  import Artemis.Helpers.Filter

  alias Artemis.KeyValue
  alias Artemis.Repo

  def call!(params \\ %{}, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting all key values")
      {:ok, result} -> result
    end
  end

  def call(params \\ %{}, user) do
    params = Artemis.Helpers.keys_to_strings(params)

    {deleted_count, _} =
      KeyValue
      |> filter_query(params, user)
      |> delete_records(params, user)

    Event.broadcast(%{records_deleted: deleted_count}, "key-value:deleted:all", params, user)

    {:ok, deleted_count}
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

  defp delete_records(query, %{"paginate" => true, "page_size" => page_size}, _user) when is_number(page_size) do
    # PostgreSQL does not directly support `LIMIT` in `DELETE` statements.
    # The functionality can be recreated using subqueries instead.
    #
    # See: https://elixirforum.com/t/why-ecto-doesnt-allow-limit-in-delete-all/33161

    subset =
      query
      |> limit(^page_size)
      |> select([m], m.id)

    delete_query = from(m in KeyValue, where: m.id in subquery(subset))

    Repo.delete_all(delete_query)
  end

  defp delete_records(query, _params, _user), do: Repo.delete_all(query)

  # Helpers - Encoding

  defp split_and_encode(value) do
    value
    |> split()
    |> Enum.map(&KeyValue.encode/1)
  end
end
