defmodule Artemis.ListJobs do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.Helpers.IBMCloudantSearch
  alias Artemis.Job

  @default_page_size 25

  def call(params \\ %{}, _user) do
    params = default_params(params)

    params
    |> get_records()
    |> parse_response(params)
  end

  defp default_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> add_page_size_param()
  end

  defp add_page_size_param(params) do
    page_size = get_page_size(params)

    Map.put(params, "page_size", page_size)
  end

  defp get_page_size(%{"page_size" => size}) when is_bitstring(size), do: String.to_integer(size)
  defp get_page_size(%{"page_size" => size}), do: size
  defp get_page_size(_), do: @default_page_size

  defp get_records(params) do
    search? =
      params
      |> Map.get("query")
      |> Artemis.Helpers.present?()

    case search? do
      true -> get_search_records(params)
      false -> get_filtered_records(params)
    end
  end

  defp get_filtered_records(params) do
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_path()

    base_query_params = %{
      execution_stats: true,
      limit: params["page_size"],
      selector: get_selector_param(params),
      use_index: ["query-indexes", "task_id"]
    }

    query_params =
      base_query_params
      |> maybe_add_bookmark_param(params)
      |> maybe_add_sort_param(params)

    IBMCloudant.Request.call(%{
      body: Jason.encode!(query_params),
      host: cloudant_host,
      method: :post,
      path: "#{cloudant_path}/_find"
    })
  end

  defp get_search_records(params) do
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_search_path()
    params = IBMCloudantSearch.add_search_param(params, Job.search_fields())

    query_params = %{
      include_docs: true,
      limit: params["page_size"],
      query: params["query"]
    }

    query_params = maybe_add_bookmark_param(query_params, params)

    IBMCloudant.Request.call(%{
      host: cloudant_host,
      method: :get,
      params: query_params,
      path: cloudant_path
    })
  end

  defp get_selector_param(params) do
    select_all_selector = %{_id: %{"$gt": nil}}
    filters = Map.get(params, "filters")

    case Artemis.Helpers.present?(filters) do
      true -> get_filter_selector(filters)
      false -> select_all_selector
    end
  end

  defp get_filter_selector(filters) do
    key =
      filters
      |> Map.keys()
      |> List.first()

    value = Map.get(filters, key)

    filter(key, value)
  end

  defp filter("first_run", value) when is_bitstring(value), do: filter("first_run", String.to_integer(value))
  defp filter(key, value), do: %{key => %{"$eq" => value}}

  defp maybe_add_bookmark_param(body, %{"bookmark" => bookmark}), do: Map.put(body, :bookmark, bookmark)
  defp maybe_add_bookmark_param(body, _), do: body

  defp maybe_add_sort_param(body, %{"order" => order}) do
    param =
      order
      |> Artemis.Helpers.Order.get_order()
      |> Enum.reduce([], fn {direction, key}, acc ->
        acc ++ [%{key => direction}]
      end)

    Map.put(body, :sort, param)
  end
  defp maybe_add_sort_param(body, _), do: body

  defp parse_response({:ok, body}, params) do
    documents = parse_response_documents(body)
    last_page? = length(documents) < params["page_size"]

    %Artemis.CloudantPage{
      bookmark_next: Map.get(body, "bookmark"),
      bookmark_previous: Map.get(params, "bookmark"),
      entries: documents,
      is_last_page: last_page?,
      total_entries: length(documents),
      total_pages: Map.get(body, "total_rows")
    }
  end

  defp parse_response({:error, _}, _), do: %Artemis.CloudantPage{}

  defp parse_response_documents(%{"rows" => rows}) do
    docs = Enum.map(rows, &Map.get(&1, "doc"))

    parse_response_documents(%{"docs" => docs})
  end

  defp parse_response_documents(%{"docs" => docs}) do
    Enum.map(docs, &Job.from_json(&1))
  end

  defp parse_response_documents(_), do: []
end
