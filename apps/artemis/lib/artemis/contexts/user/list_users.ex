defmodule Artemis.ListUsers do
  use Artemis.Context

  use Artemis.ContextCache,
    cache_reset_on_events: [
      "user:created",
      "user:deleted",
      "user:updated"
    ]

  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.User

  @default_order "name"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, user) do
    params = default_params(params)

    User
    |> distinct_query(params, default: true)
    |> preload(^Map.get(params, "preload"))
    |> search_filter(params)
    |> order_query(params)
    |> select_count(params)
    |> restrict_access(user)
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

  defp restrict_access(query, user) do
    cond do
      has?(user, "users:access:all") -> query
      has?(user, "users:access:self") -> where(query, [u], u.id == ^user.id)
      true -> where(query, [u], is_nil(u.id))
    end
  end
end
