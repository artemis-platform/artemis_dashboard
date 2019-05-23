defmodule Artemis.DeleteManyAssociatedComments do
  import Ecto.Query

  alias Artemis.Comment
  alias Artemis.Repo

  @moduledoc """
  Guarantee many-to-many comment associations are always removed even if
  database is not setup to properly cascade.

  See: https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
  """

  def call!(record, user) do
    case call(record, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting many associated comments")
      {:ok, result} -> result
      result -> result
    end
  end

  def call(record, user) when is_map(record), do: delete_comments(record, user)

  def call({:ok, record}, user) do
    case delete_comments(record, user) do
      {:error, message} -> {:error, message}
      record -> {:ok, record}
    end
  end

  def call(error, _user), do: error

  defp delete_comments(%{comments: %Ecto.Association.NotLoaded{}} = record, user) do
    record
    |> Repo.preload([:comments], force: true)
    |> delete_comments(user)
  end

  defp delete_comments(%{comments: comments} = record, _user) when length(comments) > 1 do
    comment_ids = Enum.map(comments, & &1.id)

    {total_deleted, _} =
      Comment
      |> where([c], c.id in ^comment_ids)
      |> Repo.delete_all()

    case length(comment_ids) == total_deleted do
      true -> record
      false -> {:error, "Error removing associated comments"}
    end
  end

  defp delete_comments(%{comments: comments} = record, _user) when length(comments) == 0, do: record
  defp delete_comments(_record, _user), do: {:error, "No comments association found."}
end
