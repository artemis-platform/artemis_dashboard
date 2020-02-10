defmodule Artemis.DeleteAllIncidents do
  use Artemis.Context

  alias Artemis.DeleteManyAssociatedComments
  alias Artemis.Incident
  alias Artemis.Repo

  # TODO: test all comments deleted

  def call!(params \\ %{}, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting all incidents")
      {:ok, result} -> result
    end
  end

  def call(params \\ %{}, user) do
    with_transaction(fn ->
      {:ok, _} = DeleteManyAssociatedComments.call("Incident", user)

      {deleted_count, _} = Repo.delete_all(Incident)

      Event.broadcast(%{records_deleted: deleted_count}, "incident:deleted:all", params, user)

      {:ok, deleted_count}
    end)
  end
end
