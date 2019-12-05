defmodule Artemis.Drivers.ServiceNow.ListChangeRequest do
  require Logger

  alias Artemis.Drivers.ServiceNow

  defmodule Result do
    defstruct data: [],
              meta: %{}
  end

  @moduledoc """
  Fetches change requests from the ServiceNow API.
  """

  @fetch_limit 10
  @request_path "/v1/change/standard"
  @request_timeout :timer.minutes(5)

  def call(options \\ []) do
    initial = %Result{
      data: [],
      meta: %{}
    }

    fetch_data(initial, options)
  end

  defp fetch_data(result, options) do
    with {:ok, response} <- get_page(options),
         200 <- response.status_code,
         {:ok, data} <- process_response(response) do
      result
      |> Map.put(:data, data)
      |> Map.put(:meta, response)
    else
      {:error, %HTTPoison.Error{id: nil, reason: :closed}} ->
        fetch_data(result, options)

      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        fetch_data(result, options)

      error ->
        Logger.info("Error fetching change requests from ServiceNow API: " <> inspect(error))

        return_error(error)
    end
  rescue
    error ->
      Logger.info("Error fetching change requests from ServiceNow API: " <> inspect(error))

      {:error, "Exception raised while fetching change requests from ServiceNow API"}
  end

  defp get_page(options) do
    path = Keyword.get(options, :request_path, @request_path)
    headers = Keyword.get(options, :request_headers, [])

    options = [
      params: get_request_params(options),
      recv_timeout: @request_timeout,
      timeout: @request_timeout
    ]

    ServiceNow.Request.get(path, headers, options)
  end

  defp get_request_params(options) do
    default_request_params = [
      sysparm_limit: @fetch_limit,
      sysparm_offset: 0
    ]

    custom_request_params = Keyword.get(options, :request_params, [])

    Keyword.merge(default_request_params, custom_request_params)
  end

  defp process_response(%HTTPoison.Response{body: %{"result" => entries}}) do
    {:ok, entries}
  end

  defp process_response(response), do: return_error(response)

  defp return_error({:error, message}), do: {:error, message}
  defp return_error(error), do: {:error, error}
end
