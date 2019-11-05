defmodule Artemis.CreateCustomer do
  use Artemis.Context

  alias Artemis.Customer
  alias Artemis.Helpers.Markdown
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating customer")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("customer:created", params, user)
    end)
  end

  defp insert_record(params) do
    params = create_params(params)

    %Customer{}
    |> Customer.changeset(params)
    |> Repo.insert()
  end

  defp create_params(params) do
    params = Artemis.Helpers.keys_to_strings(params)

    html =
      case Map.get(params, "notes") do
        nil -> nil
        body -> Markdown.to_html!(body)
      end

    Map.put(params, "notes_html", html)
  end
end
