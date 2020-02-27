defmodule Artemis.GetOrCreateUserTeam do
  use Artemis.Context

  alias Artemis.CreateUserTeam
  alias Artemis.GetUserTeam
  alias Artemis.Repo

  @preload [:team, :user]

  def call(user_id, team_id, params, creator) do
    params
    |> Map.put("created_by", creator)
    |> Map.put("team_id", team_id)
    |> Map.put("user_id", user_id)
    |> call(creator)
  end

  def call(params, creator) do
    params = Artemis.Helpers.keys_to_strings(params)

    case get_record(params, creator) do
      nil -> CreateUserTeam.call(params, creator)
      record -> {:ok, Repo.preload(record, @preload)}
    end
  end

  defp get_record(params, creator) when is_map(params) do
    values =
      params
      |> Map.take(["team_id", "user_id"])
      |> Artemis.Helpers.keys_to_atoms()
      |> Enum.into([])

    GetUserTeam.call(values, creator)
  end

  defp get_record(id, creator) do
    GetUserTeam.call(id, creator)
  end
end
