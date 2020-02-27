defmodule Artemis.DeleteTeam do
  use Artemis.Context

  alias Artemis.GetTeam
  alias Artemis.Repo

  def call!(id, params \\ %{}, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting team")
      {:ok, result} -> result
    end
  end

  def call(id, params \\ %{}, user) do
    id
    |> get_record(user)
    |> delete_record
    |> Event.broadcast("team:deleted", params, user)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetTeam.call(id, user)

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)
end
