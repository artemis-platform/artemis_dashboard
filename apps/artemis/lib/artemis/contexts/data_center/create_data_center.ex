defmodule Artemis.CreateDataCenter do
  use Artemis.Context

  alias Artemis.DataCenter
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating data center")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("data-center:created", params, user)
    end)
  end

  defp insert_record(params) do
    %DataCenter{}
    |> DataCenter.changeset(params)
    |> Repo.insert()
  end
end
