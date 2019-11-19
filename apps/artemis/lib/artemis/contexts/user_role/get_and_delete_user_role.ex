defmodule Artemis.GetAndDeleteUserRole do
  use Artemis.Context

  alias Artemis.DeleteUserRole
  alias Artemis.GetUserRole

  def call(user_id, role_id, params, creator) do
    params
    |> Map.put("created_by", creator)
    |> Map.put("role_id", role_id)
    |> Map.put("user_id", user_id)
    |> call(creator)
  end

  def call(params, creator) do
    params = Artemis.Helpers.keys_to_strings(params)

    case get_record(params, creator) do
      nil -> :not_found
      record -> DeleteUserRole.call(record.id, params, creator)
    end
  end

  defp get_record(params, creator) when is_map(params) do
    values =
      params
      |> Map.take(["role_id", "user_id"])
      |> Artemis.Helpers.keys_to_atoms()
      |> Enum.into([])

    GetUserRole.call(values, creator)
  end

  defp get_record(id, creator) do
    GetUserRole.call(id, creator)
  end
end
