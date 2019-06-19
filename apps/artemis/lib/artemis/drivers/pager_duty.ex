defmodule Artemis.Drivers.PagerDuty do
  use HTTPoison.Base

  @base_url "https://api.pagerduty.com/"

  def process_request_headers(headers) do
    [
      Accept: "application/vnd.pagerduty+json;version=2",
      Authorization: "Token token=#{token()}"
    ] ++ headers
  end

  def process_request_url(path), do: "#{@base_url}#{path}"

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  def token, do: Application.fetch_env!(:artemis, :pager_duty)[:token]
end
