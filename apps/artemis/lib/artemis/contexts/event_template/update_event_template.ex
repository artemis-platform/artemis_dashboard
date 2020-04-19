defmodule Artemis.UpdateEventTemplate do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.EventTemplate
  alias Artemis.GetEventTemplate
  alias Artemis.Repo

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating event_template")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> update_record(params)
      |> update_associations(params)
      |> Event.broadcast("event_template:updated", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetEventTemplate.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    record
    |> EventTemplate.changeset(params)
    |> Repo.update()
  end
end
