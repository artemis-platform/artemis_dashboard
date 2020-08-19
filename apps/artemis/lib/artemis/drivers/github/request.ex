defmodule Artemis.Drivers.Github.Request do
  use HTTPoison.Base

  def process_request_headers(headers) do
    [
      Accept: "application/vnd.github.v3+json",
      Authorization: "Basic #{get_github_token()}",
      "Content-Type": "application/json"
    ] ++ headers
  end

  def process_request_url(path), do: "#{get_github_url()}#{path}"

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  # Helpers

  defp get_github_token() do
    :artemis
    |> Application.fetch_env!(:github)
    |> Keyword.fetch!(:token)
  end

  defp get_github_url() do
    :artemis
    |> Application.fetch_env!(:github)
    |> Keyword.fetch!(:url)
  end
end
