defmodule Artemis.Drivers.IBMCloudIAM do
  use HTTPoison.Base

  def process_request_headers(headers) do
    [
      "Accept": "application/json"
    ] ++ headers
  end

  def process_request_url(path), do: "#{get_api_url()}#{path}"

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  # Helpers

  defp get_api_url() do
    :artemis
    |> Application.fetch_env!(:ibm_cloud)
    |> Keyword.fetch!(:iam_api_url)
  end
end
