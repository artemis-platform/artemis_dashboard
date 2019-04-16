defmodule Artemis.DeleteWikiPage do
  use Artemis.Context

  import Ecto.Query

  alias Artemis.Comment
  alias Artemis.Repo
  alias Artemis.WikiPage

  @preload [:comments]

  def call!(id, user) do
    case call(id, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting wiki page")
      {:ok, result} -> result
    end
  end

  def call(id, user) do
    with_transaction(fn () ->
      id
      |> get_record
      |> delete_record
      |> delete_comments
      |> Event.broadcast("wiki-page:deleted", user)
    end)
  end

  def get_record(record) when is_map(record), do: record
  def get_record(id) do
    WikiPage
    |> preload(^@preload)
    |> Repo.get(id)
  end

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)

  # Guarantee many-to-many comment associations are always removed.
  # See: https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
  defp delete_comments({:ok, %{comments: comments} = record}) when length(comments) > 1 do
    comment_ids = Enum.map(record.comments, &(&1.id))
    {total_deleted, _} = Comment
      |> where([c], c.id in ^comment_ids)
      |> Repo.delete_all

    case length(comment_ids) == total_deleted do
      true -> {:ok, record}
      false -> {:error, "Error removing associated comments"}
    end
  end
  defp delete_comments(value), do: value
end
