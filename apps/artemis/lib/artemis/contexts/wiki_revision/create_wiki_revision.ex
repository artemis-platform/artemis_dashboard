defmodule Artemis.CreateWikiRevision do
  use Artemis.Context

  alias Artemis.Repo
  alias Artemis.WikiRevision

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating wiki revision")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params
      |> insert_record
      |> Event.broadcast("wiki-revision:created", user)
    end)
  end

  defp insert_record(params) do
    params = create_params(params)

    %WikiRevision{}
    |> WikiRevision.changeset(params)
    |> Repo.insert()
  end

  defp create_params(params) do
    params = Artemis.Helpers.keys_to_strings(params)

    slug =
      params
      |> Map.get("title", "")
      |> Artemis.Helpers.generate_slug()

    Map.put(params, "slug", slug)
  end
end
