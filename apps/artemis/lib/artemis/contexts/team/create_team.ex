defmodule Artemis.CreateTeam do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.Repo
  alias Artemis.Team

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating team")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> update_associations(params)
      |> Event.broadcast("team:created", params, user)
    end)
  end

  defp insert_record(params) do
    %Team{}
    |> Team.changeset(params)
    |> Repo.insert()
  end
end
