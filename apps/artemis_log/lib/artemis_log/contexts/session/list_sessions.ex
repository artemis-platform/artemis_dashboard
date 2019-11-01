defmodule ArtemisLog.ListSessions do
  use ArtemisLog.Context

  import ArtemisLog.Helpers.Filter
  import ArtemisLog.Helpers.Search
  import Ecto.Query

  alias ArtemisLog.EventLog
  alias ArtemisLog.Repo

  @moduledoc """
  When a user logs in, they are given a `session_id` value. All actions the
  user takes during that log is considered a "session".

  Sessions are a virtual resource. The session data is not stored as a separate
  table in the database. Instead, session information is included in two
  existing resources:

  - `EventLog`. Write actions that change data like create, update and delete.
  - `HttpRequestLog`. Read actions that do not change data like index and show.

  Although session data is stored in both resources, when listing sessions it
  is sufficient to only query the `EventLog` records. At least one EventLog record
  is created each session.

  ## Implementation

  Although it is possible to return a list of unique session_id values using a
  `DISTINCT` SQL clause, it does not support ordering.

  Since the primary use case for this data is displaying paginated data in
  historical order, the context uses the more complex and robust `SELECT` and
  `GROUP_BY` method of querying data.

  For more information see: https://stackoverflow.com/q/5391564
  """

  @default_page_size 10
  @default_paginate true

  def call(params \\ %{}, user) do
    params = default_params(params)

    EventLog
    |> filter_query(params, user)
    |> search_filter(params)
    |> group_query(params)
    |> restrict_access(user)
    |> get_records(params)
  end

  defp default_params(params) do
    params
    |> ArtemisLog.Helpers.keys_to_strings()
    |> Map.put_new("page", Map.get(params, "page_number", 1))
    |> Map.put_new("page_size", @default_page_size)
    |> Map.put_new("paginate", @default_paginate)
  end

  defp filter_query(query, %{"filters" => filters}, _user) when is_map(filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter(acc, key, value)
    end)
  end

  defp filter_query(query, _params, _user), do: query

  defp filter(query, _key, nil), do: query
  defp filter(query, _key, ""), do: query
  defp filter(query, "session_id", value), do: where(query, [el], el.session_id in ^split(value))
  defp filter(query, "user_id", value), do: where(query, [el], el.user_id in ^split(value))
  defp filter(query, "user_name", value), do: where(query, [el], el.user_name in ^split(value))
  defp filter(query, _key, _value), do: query

  defp group_query(query, _params) do
    query
    |> select_fields()
    |> group_by([:session_id])
    |> order_by([q], desc: max(q.inserted_at))
    |> where([q], not is_nil(q.session_id))
  end

  defp select_fields(query) do
    select(
      query,
      [q],
      %{
        inserted_at: max(q.inserted_at),
        session_id: q.session_id,
        user_name: max(q.user_name)
      }
    )
  end

  defp restrict_access(query, user) do
    cond do
      has?(user, "sessions:access:all") -> query
      has?(user, "sessions:access:self") -> where(query, [el], el.user_id == ^user.id)
      true -> where(query, [el], is_nil(el.id))
    end
  end

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, params)
  defp get_records(query, _params), do: Repo.all(query)
end
