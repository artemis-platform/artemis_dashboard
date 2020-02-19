defmodule Artemis.GetAndDeleteUserTeam do
  use Artemis.Context

  alias Artemis.DeleteUserTeam
  alias Artemis.GetUserTeam

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
      nil -> :not_found
      record -> DeleteUserTeam.call(record.id, params, creator)
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
