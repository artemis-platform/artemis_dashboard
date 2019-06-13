defmodule Artemis.Drivers.IBMCloudant do
  use HTTPoison.Base

  def process_request_headers(headers) do
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!()

    [
      "Accept": "application/json",
      "Authorization": "Bearer #{token}"
    ] ++ headers
  end

  def process_request_url(options \\ []) do
    domain = Keyword.get(options, :domain)
    database = Keyword.get(options, :database)
    document = Keyword.get(options, :document)

    "https://#{domain}/#{database}/#{document}"
  end

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end
end
