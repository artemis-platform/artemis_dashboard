defmodule Artemis.ListJobs do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.Job

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
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_path()
    select_all_selector = %{_id: %{"$gt": nil}}

    body = %{
      execution_stats: true,
      fields: ["_id", "name", "status", "first_run"],
      limit: params["page_size"],
      selector: select_all_selector
    }

    IBMCloudant.Request.call(%{
      body: Jason.encode!(body),
      host: cloudant_host,
      method: :post,
      path: "#{cloudant_path}/_find"
    })
  end

  defp get_search_records(%{"query" => query}) do
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_search_path()

    query_params = [
      include_docs: true,
      query: query
    ]

    IBMCloudant.Request.call(%{
      host: cloudant_host,
      method: :get,
      params: query_params,
      path: cloudant_path
    })
  end

  defp parse_response({:ok, body}), do: parse_response_body(body)
  defp parse_response({:error, _}), do: []

  defp parse_response_body(%{"rows" => rows}) do
    docs = Enum.map(rows, &Map.get(&1, "doc"))

    parse_response_body(%{"docs" => docs})
  end

  defp parse_response_body(%{"docs" => docs}) do
    Enum.map(docs, &Job.from_json(&1))
  end
end
