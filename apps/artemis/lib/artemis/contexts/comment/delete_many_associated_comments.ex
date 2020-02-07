defmodule Artemis.DeleteManyAssociatedComments do
  import Ecto.Query

  alias Artemis.Comment
  alias Artemis.Repo

  def call!(resource_type, resource_id \\ nil, user) do
    case call(resource_type, resource_id, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting many associated comments")
      {:ok, result} -> result
      result -> result
    end
  end

  def call(resource_type, resource_id \\ nil, user) do
    case delete_records(resource_type, resource_id, user) do
      {:error, message} -> {:error, message}
      {total, _} -> {:ok, %{total: total}}
    end
  end

  defp delete_records(resource_type, resource_id, _user) do
    Comment
    |> where([c], c.resource_type == ^resource_type)
    |> maybe_where_resource_id(resource_id)
    |> Repo.delete_all()
  end

  defp maybe_where_resource_id(query, nil), do: query

  defp maybe_where_resource_id(query, resource_id) when is_integer(resource_id) do
    maybe_where_resource_id(query, Integer.to_string(resource_id))
  end

  defp maybe_where_resource_id(query, resource_id) do
    where(query, [c], c.resource_id == ^resource_id)
  end
end
