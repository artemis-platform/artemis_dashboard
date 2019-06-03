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
      |> DeleteManyAssociatedComments.call(user)
      |> delete_record
      |> Event.broadcast("wiki-page:deleted", user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetWikiPage.call(id, user)

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)
end
