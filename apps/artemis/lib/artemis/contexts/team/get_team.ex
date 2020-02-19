defmodule Artemis.GetTeam do
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.Team

  @default_preload []

  def call!(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by!/2)
  end

  def call(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by/2)
  end

  defp get_record(value, options, get_by) when not is_list(value) do
    get_record([id: value], options, get_by)
  end

  defp get_record(value, options, get_by) do
    Team
    |> select_fields()
    |> preload(^Keyword.get(options, :preload, @default_preload))
    |> get_by.(value)
  end

  defp select_fields(query) do
    query
    |> group_by([team], team.id)
    |> join(:left, [team], user_teams in assoc(team, :user_teams))
    |> select([team, ..., user_teams], %Team{team | user_count: count(user_teams.id)})
  end
end
