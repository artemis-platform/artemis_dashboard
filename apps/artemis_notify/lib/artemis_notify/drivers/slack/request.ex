defmodule ArtemisNotify.Drivers.Slack.Request do
  use HTTPoison.Base

  def process_request_headers(headers) do
    [
      Accept: "application/json",
      "Content-Type": "application/json"
    ] ++ headers
  end

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end
end
