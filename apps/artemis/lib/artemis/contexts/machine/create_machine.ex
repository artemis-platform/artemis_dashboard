defmodule Artemis.CreateMachine do
  use Artemis.Context

  alias Artemis.Machine
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating machine")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("machine:created", params, user)
    end)
  end

  defp insert_record(params) do
    %Machine{}
    |> Machine.changeset(params)
    |> Repo.insert()
  end
end
