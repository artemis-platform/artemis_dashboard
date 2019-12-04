defmodule Artemis.Drivers.PagerDuty.ListOnCalls do
  require Logger

  alias Artemis.Drivers.PagerDuty

  defmodule Result do
    defstruct data: [],
              meta: %{}
  end

  @moduledoc """
  Fetches on call from the PagerDuty API.

  ## Paginated Results

  The PagerDuty API sets a low limit for how many records may be returned in a
  single request. As a consequence, it's common for many requests to be sent in
  order to return the complete result set.

  This module will automatically request the next page of results until it
  has returned all matching records.

  The default behaviour is to return the complete result set at the end.

  Optionally, a callback function can be sent to batch process results after
  each page.

  ## Options

    :callback
    :request_headers
    :request_params
    :request_path

  """

  @fetch_limit 50
  @request_path "/oncalls"

  def call(options \\ []) do
    initial_data = %Result{
      data: [],
      meta: %{}
    }

    fetch_data(initial_data, options)
  end

  defp fetch_data(acc, options) do
    with {:ok, response} <- get_page(options),
         200 <- response.status_code,
         {:ok, all_on_calls} <- process_response(response) do
      callback_results = apply_callback(all_on_calls, options)

      on_calls = Map.get(callback_results, :on_calls, all_on_calls)
      options = Map.get(callback_results, :options, options)

      acc =
        acc
        |> Map.update!(:data, &Kernel.++(&1, on_calls))
        |> Map.update!(:meta, &Map.put(&1, :api_response, response))

      more? = Artemis.Helpers.deep_get(response, [:body, "more"], false)

      case more? do
        false -> {:ok, acc}
        true -> fetch_data(acc, get_updated_options(options, all_on_calls))
      end
    else
      {:error, %HTTPoison.Error{id: nil, reason: :closed}} ->
        fetch_data(acc, options)

      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        fetch_data(acc, options)

      error ->
        Logger.info("Error fetching on calls from PagerDuty API: " <> inspect(error))

        return_error(error)
    end
  rescue
    error ->
      Logger.info("Error fetching on calls from PagerDuty API: " <> inspect(error))

      {:error, "Exception raised while fetching on callsfrom PagerDuty API"}
  end

  defp get_page(options) do
    path = Keyword.get(options, :request_path, @request_path)
    headers = Keyword.get(options, :request_headers, [])
    options = [params: get_request_params(options)]

    PagerDuty.Request.get(path, headers, options)
  end

  defp get_request_params(options) do
    default_request_params = [
      limit: @fetch_limit,
      offset: 0
    ]

    custom_request_params = Keyword.get(options, :request_params, [])

    Keyword.merge(default_request_params, custom_request_params)
  end

  defp process_response(%HTTPoison.Response{body: %{"oncalls" => entries}}) do
    {:ok, entries}
  end

  defp process_response(response), do: return_error(response)

  defp apply_callback(on_calls, options) do
    case Keyword.get(options, :callback) do
      nil -> %{on_calls: on_calls, options: options}
      callback -> callback.(on_calls, options)
    end
  end

  defp get_updated_options(options, _on_calls) do
    request_params = Keyword.get(options, :request_params, [])
    current_offset = Keyword.get(request_params, :offset, 0)
    next_offset = current_offset + 1
    updated_request_params = Keyword.put(request_params, :offset, next_offset)

    Keyword.put(options, :request_params, updated_request_params)
  end

  defp return_error({:error, message}), do: {:error, message}
  defp return_error(error), do: {:error, error}
end
