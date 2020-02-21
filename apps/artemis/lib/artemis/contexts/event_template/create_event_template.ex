defmodule Artemis.CreateEventTemplate do
  use Artemis.Context

  alias Artemis.EventTemplate
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating event_template")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("event_template:created", params, user)
    end)
  end

  defp insert_record(params) do
    %EventTemplate{}
    |> EventTemplate.changeset(params)
    |> Repo.insert()
  end
end
