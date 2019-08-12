defmodule Artemis.UpdateCustomer do
  use Artemis.Context

  alias Artemis.Customer
  alias Artemis.GetCustomer
  alias Artemis.Helpers.Markdown
  alias Artemis.Repo

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating customer")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      id
      |> get_record(user)
      |> update_record(params)
      |> Event.broadcast("customer:updated", user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetCustomer.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    params = update_params(record, params)

    record
    |> Customer.changeset(params)
    |> Repo.update()
  end

  defp update_params(_record, params) do
    params = Artemis.Helpers.keys_to_strings(params)

    html =
      case Map.get(params, "notes") do
        nil -> nil
        body -> Markdown.to_html!(body)
      end

    Map.put(params, "notes_html", html)
  end
end
