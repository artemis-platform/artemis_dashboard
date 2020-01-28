defmodule Artemis.CreateCloud do
  use Artemis.Context

  alias Artemis.Cloud
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating cloud")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("cloud:created", params, user)
    end)
  end

  defp insert_record(params) do
    %Cloud{}
    |> Cloud.changeset(params)
    |> Repo.insert()
  end
end
