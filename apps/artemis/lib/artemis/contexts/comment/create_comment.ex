defmodule Artemis.CreateComment do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.Comment
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating comment")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn () ->
      params
      |> insert_record
      |> update_associations(params)
      |> Event.broadcast("comment:created", user)
    end)
  end

  defp insert_record(params) do
    %Comment{}
    |> Comment.changeset(params)
    |> Repo.insert
  end
end
