defmodule Artemis.UpdateComment do
  use Artemis.Context
  use Assoc.Updater, repo: Artemis.Repo

  alias Artemis.Comment
  alias Artemis.Helpers.Markdown
  alias Artemis.Repo

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating comment")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn () ->
      id
      |> get_record
      |> update_record(params)
      |> update_associations(params)
      |> Event.broadcast("comment:updated", user)
    end)
  end

  def get_record(record) when is_map(record), do: record
  def get_record(id), do: Repo.get(Comment, id)

  defp update_record(nil, _params), do: {:error, "Record not found"}
  defp update_record(record, params) do
    params = update_params(record, params)

    record
    |> Comment.changeset(params)
    |> Repo.update
  end

  defp update_params(_record, params) do
    params = Artemis.Helpers.keys_to_strings(params)

    case Map.get(params, "body") do
      nil -> params
      body -> Map.put(params, "body_html", Markdown.to_html!(body))
    end
  end
end
