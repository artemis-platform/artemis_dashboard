defmodule Artemis.Drivers.IBMCloudant do
  use HTTPoison.Base

  require Logger

  defmodule CloudantError do
    defexception message: "IBM Cloudant Error"
  end

  @doc """
  Wraps the HTTPoison.request/1 function. Parses the response and either returns:

    {:ok, body}
    {:error, message}

  Where on success `body` is the decoded response body, and on failure `message` is either
  the HTTPoison error message or the response body when a 400/500 status code is received.
  """
  def call(params) do
    struct(HTTPoison.Request, params)
    |> request()
    |> simplified_response()
  end

  def call!(params) do
    case call(params) do
      {:error, message} -> raise(CloudantError, message)
      {:ok, result} -> result
    end
  end

  # Callbacks

  def process_request_headers(headers) do
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!()

    [
      Accept: "application/json",
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json"
    ] ++ headers
  end

  def process_request_url(path) do
    "https://#{path}"
  end

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  # Helpers

  defp simplified_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    {:ok, body}
  end
  defp simplified_response({:ok, %{body: body, status_code: status_code} = request}) when status_code in 400..599 do
    Logger.debug("Error response for Cloudant HTTP request: " <> inspect(request))

    {:error, body}
  end
  defp simplified_response(error) do
    Logger.info("Error response for Cloudant HTTP request: " <> inspect(error))

    error
  end
end
