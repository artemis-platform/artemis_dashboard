defmodule Artemis.Drivers.PagerDuty.Request do
  use HTTPoison.Base

  def process_request_headers(headers) do
    [
      Accept: "application/vnd.pagerduty+json;version=2",
      Authorization: "Token token=#{get_api_token()}"
    ] ++ headers
  end

  def process_request_url(path), do: "#{get_api_url()}#{path}"

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  def get_api_token, do: Application.fetch_env!(:artemis, :pager_duty)[:api_token]

  def get_api_url, do: Application.fetch_env!(:artemis, :pager_duty)[:api_url]
end
