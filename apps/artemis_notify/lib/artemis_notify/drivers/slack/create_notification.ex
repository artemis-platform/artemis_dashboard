defmodule ArtemisNotify.Drivers.Slack.CreateNotification do
  defmodule Error do
    defexception message: "Error"
  end

  require Logger

  @moduledoc """
  Create a Slack Notification
  """

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(ArtemisNotify.Drivers.Slack.CreateNotification.Error, "Error creating slack notification")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    params
    |> send_request(user)
    |> parse_response()
  end

  # Helpers

  defp send_request(params, _user) do
    params = Artemis.Helpers.keys_to_strings(params)
    url = Map.get(params, "url")
    payload = Map.get(params, "payload")

    ArtemisNotify.Drivers.Slack.Request.post(url, payload)
  end

  defp parse_response({_, %HTTPoison.Response{} = response}) do
    status = parse_status_code(response)

    {status, response}
  end

  defp parse_response(error), do: error

  defp parse_status_code(%{status_code: status_code}) when status_code in 200..399, do: :ok
  defp parse_status_code(_error), do: :error
end
