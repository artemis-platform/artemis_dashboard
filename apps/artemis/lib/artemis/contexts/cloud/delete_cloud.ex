defmodule Artemis.DeleteCloud do
  use Artemis.Context

  alias Artemis.DeleteManyAssociatedComments
  alias Artemis.GetCloud
  alias Artemis.Repo

  def call!(id, params \\ %{}, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting cloud")
      {:ok, result} -> result
    end
  end

  def call(id, params \\ %{}, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> delete_associated_comments(user)
      |> delete_record
      |> Event.broadcast("cloud:deleted", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetCloud.call(id, user)

  defp delete_associated_comments(record, user) do
    resource_type = "Cloud"
    resource_id = record.id

    {:ok, _} = DeleteManyAssociatedComments.call(resource_type, resource_id, user)

    record
  rescue
    _ -> record
  end

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)
end
