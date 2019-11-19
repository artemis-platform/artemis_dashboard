defmodule Artemis.CreateUserRole do
  use Artemis.Context

  alias Artemis.Repo
  alias Artemis.UserRole

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating user role")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("user-role:created", params, user)
    end)
  end

  defp insert_record(params) do
    %UserRole{}
    |> UserRole.changeset(params)
    |> Repo.insert()
  end
end
