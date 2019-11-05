defmodule Artemis.UpdateTag do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.GenerateTagParams
  alias Artemis.GetTag
  alias Artemis.Repo
  alias Artemis.Tag

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating tag")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> update_record(params)
      |> update_associations(params)
      |> Event.broadcast("tag:updated", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetTag.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    params = GenerateTagParams.call(params, record)

    record
    |> Tag.changeset(params)
    |> Repo.update()
  end
end
