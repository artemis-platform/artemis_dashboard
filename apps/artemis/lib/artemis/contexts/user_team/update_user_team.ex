defmodule Artemis.UpdateUserTeam do
  use Artemis.Context

  alias Artemis.GetUserTeam
  alias Artemis.Repo
  alias Artemis.UserTeam

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating user team")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> update_record(params)
      |> Event.broadcast("user-team:updated", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetUserTeam.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    record
    |> UserTeam.changeset(params)
    |> Repo.update()
  end
end
