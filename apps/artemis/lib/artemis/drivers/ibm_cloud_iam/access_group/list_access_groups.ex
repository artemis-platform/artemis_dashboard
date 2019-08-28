defmodule Artemis.Drivers.IBMCloudIAM.ListAccessGroups do
  alias Artemis.Drivers.IBMCloudIAM

  @token :ibm_cloud_iam_access_groups
  @page_limit 100
  @page_maximum 10_000
  @page_path "/v2/groups"
  @page_key "groups"

  def call(account_id) do
    get_all_records(account_id)
  end

  # Helpers

  defp get_all_records(account_id) do
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!(@token)
    page_range = Range.new(0, @page_maximum)

    Enum.reduce_while(page_range, [], fn page, acc ->
      {:ok, result} = get_page(token, account_id, page)

      data = Map.get(result, @page_key)
      updated = data ++ acc

      case last_page?(result) do
        true -> {:halt, Enum.reverse(updated)}
        false -> {:cont, updated}
      end
    end)
  end

  defp get_page(token, account_id, offset) do
    with {:ok, response} <- request_page(token, account_id, offset),
         {:ok, data} <- process_response(response) do
      {:ok, data}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp request_page(token, account_id, offset) do
    query_params = [
      account_id: account_id,
      limit: @page_limit,
      offset: offset
    ]

    query_string = Plug.Conn.Query.encode(query_params)

    path = "#{@page_path}?#{query_string}"
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
