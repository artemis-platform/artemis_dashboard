defmodule Artemis.CreateEventQuestion do
  use Artemis.Context

  alias Artemis.EventQuestion
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating event_question")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("event_question:created", params, user)
    end)
  end

  defp insert_record(params) do
    %EventQuestion{}
    |> EventQuestion.changeset(params)
    |> Repo.insert()
  end
end
