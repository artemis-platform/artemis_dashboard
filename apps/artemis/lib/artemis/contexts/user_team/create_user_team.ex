defmodule Artemis.CreateUserTeam do
  use Artemis.Context

  alias Artemis.Repo
  alias Artemis.UserTeam

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating user team")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("user-team:created", params, user)
    end)
  end

  defp insert_record(params) do
    %UserTeam{}
    |> UserTeam.changeset(params)
    |> Repo.insert()
  end
end
