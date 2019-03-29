defmodule Artemis.ListWikiRevisions do
  use Artemis.Context

  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.WikiRevision

  @default_order "-updated_at"
  @default_page_size 25
  @default_preload [:user]

  def call(params \\ %{}, _user) do
    params = default_params(params)

    WikiRevision
    |> preload(^Map.get(params, "preload"))
    |> order_query(params)
    |> get_records(params)
  end

  defp default_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> Map.put_new("order", @default_order)
    |> Map.put_new("page_size", @default_page_size)
    |> Map.put_new("preload", @default_preload)
  end

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
