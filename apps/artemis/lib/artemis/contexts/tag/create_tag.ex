defmodule Artemis.CreateTag do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.GenerateTagParams
  alias Artemis.Repo
  alias Artemis.Tag

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating tag")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn () ->
      params
      |> insert_record
      |> update_associations(params)
      |> Event.broadcast("tag:created", user)
    end)
  end

  defp insert_record(params) do
    params = GenerateTagParams.call(params)

    %Tag{}
    |> Tag.changeset(params)
    |> Repo.insert
  end
end
