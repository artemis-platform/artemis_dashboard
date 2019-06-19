defmodule Artemis.ListSharedJobs do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.SharedJob

  @cloudant_database "jobs"
  @cloudant_search_design_doc "text-search"
  @cloudant_search_index "text-index"
  # TODO: move to config
  @cloudant_host "b133e32d-f26f-4240-aaff-301c222501d1-bluemix.cloudantnosqldb.appdomain.cloud"
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
    path = "#{@cloudant_host}/#{@cloudant_database}/_find"
    select_all_selector = %{_id: %{"$gt": nil}}
    sort = [%{first_run: "desc"}]

    request_params = %{
      execution_stats: true,
      fields: ["_id", "name", "status", "first_run"],
      limit: params["page_size"],
      selector: select_all_selector
      # TODO
      # sort: sort
      # TODO
      # use_index: https://docs.couchdb.org/en/stable/api/database/find.html?highlight=pagination#post--db-_find
      # TODO
      # skip: # page_size * page_number 
    }

    IBMCloudant.post(path, Jason.encode!(request_params))
  end

  defp get_search_records(%{"query" => query}) do
    # TODO: create Cloudant migrator to add text search index if missing
    base = "#{@cloudant_host}/#{@cloudant_database}"
    design_doc = "_design/#{@cloudant_search_design_doc}"
    search_index = "_search/#{@cloudant_search_index}"
    path = "#{base}/#{design_doc}/#{search_index}"

    # TODO: in the controller, add a `*` at the end
    #  - Unless it contains a `:` meaning it's a already a specific query
    # Alternatively, add a `fuzzy_search` boolean param?
    #  - No

    request_params = [
      params: [
        include_docs: true,
        query: query
      ]
    ]

    IBMCloudant.get(path, [], request_params)
  end

  defp parse_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    _warning = Map.get(body, "warning")
    _execution_time = Artemis.Helpers.deep_get(body, ["execution_stats", "execution_time_ms"])
    _total_docs_examined = Artemis.Helpers.deep_get(body, ["execution_stats", "total_docs_examined"])
    _bookmark = Map.get(body, "bookmark")

    parse_response_body(body)
  end

  defp parse_response({:ok, %{status_code: status_code} = response}) when status_code in 400..599 do
    Logger.info("Error listing shared jobs: " <> inspect(response))

    []
  end

  defp parse_response({:error, message}) do
    Logger.info("Error: " <> inspect(message))

    []
  end

  defp parse_response_body(%{"rows" => rows}) do
    docs = Enum.map(rows, &Map.get(&1, "doc"))

    parse_response_body(%{"docs" => docs})
  end

  defp parse_response_body(%{"docs" => docs}) do
    Enum.map(docs, &SharedJob.from_json(&1))
  end
end
