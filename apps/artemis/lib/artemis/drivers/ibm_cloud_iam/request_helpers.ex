defmodule Artemis.Drivers.IBMCloudIAM.Request.Helpers do
  alias Artemis.Drivers.IBMCloudIAM

  @default_token_key :ibm_cloud_iam_access_groups
  @default_limit 100
  @default_page_maximum 10_000

  @doc """
  Walks through paginated API endpoints and returns all data
  """
  def get_all_paginated_records(passed_options \\ []) do
    options = get_options(passed_options)

    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!(options[:token_key])
    page_range = Range.new(0, options[:page_maximum])

    Enum.reduce_while(page_range, [], fn page, acc ->
      {:ok, result} = get_page(page, token, options)

      data = Map.get(result, options[:data_key])
      updated = data ++ acc

      case last_page?(result) do
        true -> {:halt, Enum.reverse(updated)}
        false -> {:cont, updated}
      end
    end)
  end

  # Helpers

  defp get_options(passed_options) do
    default_options = [
      limit: @default_limit,
      page_maximum: @default_page_maximum,
      query_params: [],
      token_key: @default_token_key
    ]

    Keyword.merge(default_options, passed_options)
  end

  defp get_page(page, token, options) do
    with {:ok, response} <- request_page(page, token, options),
         {:ok, data} <- process_response(response) do
      {:ok, data}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp request_page(page, token, options) do
    default_query_params = [
      limit: options[:limit],
      offset: page
    ]

    query_params = Keyword.merge(default_query_params, options[:query_params])
    query_string = Plug.Conn.Query.encode(query_params)

    path = "#{options[:path]}?#{query_string}"
    headers = [Authorization: "Bearer #{token}"]
    options = []

    IBMCloudIAM.Request.get(path, headers, options)
  end

  defp process_response(%{body: body, status_code: 200}), do: {:ok, body}

  defp process_response(%{body: %{"errorCode" => code, "errorMessage" => message}}) do
    {:error, "IBM Cloud IAM error #{code}: #{message}"}
  end

  defp process_response(_), do: {:error, "Unknown error response from IBM Cloud IAM"}

  defp last_page?(%{"limit" => limit, "offset" => offset, "total_count" => total_count}) do
    current_count = limit * (offset + 1)

    current_count >= total_count
  end
end
