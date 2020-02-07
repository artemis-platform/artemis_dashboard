defmodule Artemis.DeleteIncident do
  use Artemis.Context

  alias Artemis.DeleteManyAssociatedComments
  alias Artemis.GetIncident
  alias Artemis.Repo

  def call!(id, params \\ %{}, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting incident")
      {:ok, result} -> result
    end
  end

  def call(id, params \\ %{}, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> delete_associated_comments(user)
      |> delete_record
      |> Event.broadcast("incident:deleted", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetIncident.call(id, user)

  def delete_associated_comments(record, user) do
    resource_type = "Incident"
    resource_id = record.id

    {:ok, _} = DeleteManyAssociatedComments.call(resource_type, resource_id, user)

    record
  end

  defp delete_record(nil), do: {:error, "Record not found"}
  defp delete_record(record), do: Repo.delete(record)
end
