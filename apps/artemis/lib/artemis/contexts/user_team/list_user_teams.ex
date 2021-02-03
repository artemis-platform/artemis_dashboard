defmodule Artemis.ListUserTeams do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.UserTeam

  @default_order "inserted_at"
  @default_page_size 25
  @default_preload [:created_by, :team, :user]

  def call(params \\ %{}, user) do
    params = default_params(params)

    UserTeam
    |> select_query(UserTeam, params)
    |> distinct_query(params, default: true)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> order_query(params)
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

  defp filter(query, "created_by_id", value), do: where(query, [i], i.created_by_id in ^split(value))
  defp filter(query, "team_id", value), do: where(query, [i], i.team_id in ^split(value))
  defp filter(query, "type", value), do: where(query, [i], i.type in ^split(value))
  defp filter(query, "user_id", value), do: where(query, [i], i.user_id in ^split(value))

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
