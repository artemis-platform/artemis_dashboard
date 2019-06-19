defmodule Artemis.ListSharedJobs do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.SharedJob

  @default_order "slug"
  @default_page_size 25

  def call(params \\ %{}, _user) do
    params
    |> default_params()
    |> get_records()
    |> parse_response()
  end

  defp default_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> Map.put_new("order", @default_order)
    |> Map.put_new("page_size", @default_page_size)
  end

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
    path = "#{SharedJob.cloudant_path()}/_find"
    select_all_selector = %{_id: %{"$gt": nil}}

    body = %{
      execution_stats: true,
      fields: ["_id", "name", "status", "first_run"],
      limit: params["page_size"],
      selector: select_all_selector
    }

    IBMCloudant.call(%{
      body: Jason.encode!(body),
      method: :post,
      url: path
    })
  end

  defp get_search_records(%{"query" => query}) do
    host = SharedJob.cloudant_host()
    database = SharedJob.cloudant_database()
    path = Artemis.Helpers.CloudantSearch.get_query_url(host, database)
    query_params = [
      include_docs: true,
      query: query
    ]

    IBMCloudant.call(%{
      method: :get,
      params: query_params,
      url: path
    })
  end

  defp parse_response({:ok, body}), do: parse_response_body(body)
  defp parse_response({:error, _}), do: []

  defp parse_response_body(%{"rows" => rows}) do
    docs = Enum.map(rows, &Map.get(&1, "doc"))

    parse_response_body(%{"docs" => docs})
  end

  defp parse_response_body(%{"docs" => docs}) do
    Enum.map(docs, &SharedJob.from_json(&1))
  end
end
