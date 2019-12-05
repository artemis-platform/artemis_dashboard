defmodule Artemis.Drivers.ServiceNow.Request do
  use HTTPoison.Base

  def process_request_headers(headers) do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: "Bearer #{get_api_token()}"
    ] ++ headers
  end

  def process_request_url(path), do: "#{get_api_url()}#{path}"

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  def get_api_token, do: Application.fetch_env!(:artemis, :service_now)[:api_token]

  def get_api_url, do: Application.fetch_env!(:artemis, :service_now)[:api_url]
end
