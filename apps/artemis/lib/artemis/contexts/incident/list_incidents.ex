defmodule Artemis.ListIncidents do
  use Artemis.Context

  import Artemis.Helpers.Filter
  import Artemis.Helpers.Search
  import Ecto.Query

  alias Artemis.Incident
  alias Artemis.Repo

  @default_order "-triggered_at"
  @default_page_size 25
  @default_preload []

  def call(params \\ %{}, user) do
    params = default_params(params)

    Incident
    |> select_query(Incident, params)
    |> distinct_query(params, default: true)
    |> preload(^Map.get(params, "preload"))
    |> filter_query(params, user)
    |> search_filter(params)
    |> order_query(params)
    |> select_count(params)
    |> get_records(params)
  end

  defp default_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> Map.put_new("order", @default_order)
    |> Map.put_new("page_size", @default_page_size)
    |> Map.put_new("preload", @default_preload)
  end

  defp filter_query(query, %{"filters" => filters}, _user) when is_map(filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter(acc, key, value)
    end)
  end

  defp filter_query(query, _params, _user), do: query

  defp filter(query, _key, nil), do: query
  defp filter(query, _key, ""), do: query
  defp filter(query, "acknowledged_by", value), do: where(query, [i], i.acknowledged_by in ^split(value))
  defp filter(query, "resolved_by", value), do: where(query, [i], i.resolved_by in ^split(value))
  defp filter(query, "service_id", value), do: where(query, [i], i.service_id in ^split(value))
  defp filter(query, "severity", value), do: where(query, [i], i.severity in ^split(value))
  defp filter(query, "source", value), do: where(query, [i], i.source in ^split(value))
  defp filter(query, "status", value), do: where(query, [i], i.status in ^split(value))

  defp filter(query, "tags", value) do
    query
    |> join(:left, [incidents], tags in assoc(incidents, :tags))
    |> where([..., t], t.slug in ^split(value))
  end

  defp filter(query, "team_id", value), do: where(query, [i], i.team_id in ^split(value))
  defp filter(query, "triggered_after", value), do: where(query, [i], i.triggered_at >= ^value)
  defp filter(query, "triggered_before", value), do: where(query, [i], i.triggered_at < ^value)
  defp filter(query, _key, _value), do: query

  defp get_records(query, %{"paginate" => true} = params), do: Repo.paginate(query, pagination_params(params))
  defp get_records(query, _params), do: Repo.all(query)
end
