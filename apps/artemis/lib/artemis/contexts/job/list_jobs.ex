defmodule Artemis.ListJobs do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.Helpers.IBMCloudantSearch
  alias Artemis.Job

  @default_order "slug"
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
    |> Map.put_new("order", @default_order)
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
    select_all_selector = %{_id: %{"$gt": nil}}

    query_params = %{
      execution_stats: true,
      limit: params["page_size"],
      selector: select_all_selector
    }

    query_params = maybe_add_bookmark(query_params, params)

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

    query_params = maybe_add_bookmark(query_params, params)

    IBMCloudant.Request.call(%{
      host: cloudant_host,
      method: :get,
      params: query_params,
      path: cloudant_path
    })
  end

  defp maybe_add_bookmark(body, %{"bookmark" => bookmark}), do: Map.put(body, :bookmark, bookmark)
  defp maybe_add_bookmark(body, _), do: body

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
