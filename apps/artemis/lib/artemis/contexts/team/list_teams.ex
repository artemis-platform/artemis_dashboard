defmodule Artemis.ListTeams do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.Team

  @default_order "slug"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, user) do
    params = default_params(params)

    Team
    |> distinct(true)
    |> select_fields()
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> search_filter(params)
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

  defp select_fields(query) do
    query
    |> group_by([team], team.id)
    |> join(:left, [team], user_teams in assoc(team, :user_teams))
    |> select([team, ..., user_teams], %Team{team | user_count: count(user_teams.id)})
  end

  defp filter_query(query, %{"filters" => filters}, _user) when is_map(filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter(acc, key, value)
    end)
  end

  defp filter_query(query, _params, _user), do: query

  defp filter(query, "name", value), do: where(query, [r], r.name in ^split(value))
  defp filter(query, "slug", value), do: where(query, [r], r.slug in ^split(value))

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
