defmodule Artemis.DeleteWikiPage do
  use Artemis.Context

  alias Artemis.DeleteManyAssociatedComments
  alias Artemis.GetWikiPage
  alias Artemis.Repo

  def call!(id, user) do
    case call(id, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting wiki page")
      {:ok, result} -> result
    end
  end

  def call(id, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> delete_associated_comments(user)
      |> delete_record
      |> Event.broadcast("wiki-page:deleted", user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetWikiPage.call(id, user)

  def delete_associated_comments(record, user) do
    resource_type = "WikiPage"
    resource_id = record.id

    {:ok, _} = DeleteManyAssociatedComments.call(resource_type, resource_id, user)

    record
  rescue
    _ -> record
  end

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)
end
