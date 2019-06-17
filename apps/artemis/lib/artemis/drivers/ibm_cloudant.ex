defmodule Artemis.Drivers.IBMCloudant do
  use HTTPoison.Base

  def process_request_headers(headers) do
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!()

    [
      "Accept": "application/json",
      "Authorization": "Bearer #{token}",
      "Content-Type": "application/json"
    ] ++ headers
  end

  def process_request_url(path) do
    # domain = Keyword.get(options, :domain)
    # database = Keyword.get(options, :database)
    # document = Keyword.get(options, :document)

    "https://#{path}"
  end

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end
end
