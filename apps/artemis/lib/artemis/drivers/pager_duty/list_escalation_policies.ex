defmodule Artemis.Drivers.PagerDuty.ListEscalationPolicies do
  require Logger

  alias Artemis.Drivers.PagerDuty

  defmodule Result do
    defstruct data: [],
              meta: %{}
  end

  @moduledoc """
  Fetches escalation policies from the PagerDuty API.

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
  @request_path "/escalation_policies"

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
         {:ok, all_escalation_policies} <- process_response(response) do
      callback_results = apply_callback(all_escalation_policies, options)

      escalation_policies = Map.get(callback_results, :escalation_policies, all_escalation_policies)
      options = Map.get(callback_results, :options, options)

      acc =
        acc
        |> Map.update!(:data, &Kernel.++(&1, escalation_policies))
        |> Map.update!(:meta, &Map.put(&1, :api_response, response))

      more? = Artemis.Helpers.deep_get(response, [:body, "more"], false)

      case more? do
        false -> {:ok, acc}
        true -> fetch_data(acc, get_updated_options(options, all_escalation_policies))
      end
    else
      {:error, %HTTPoison.Error{id: nil, reason: :closed}} -> fetch_data(acc, options)
      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} -> fetch_data(acc, options)
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    error ->
      Logger.info("Error fetching escalation policies from PagerDuty API: " <> inspect(error))

      {:error, "Exception raised while fetching escalation policies from PagerDuty API"}
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

  defp get_default_until_date() do
    Timex.now()
    |> Timex.shift(hours: 1)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp process_response(%HTTPoison.Response{body: %{"escalation_policies" => entries}}) do
    {:ok, entries}
  rescue
    _ -> {:error, "Error processing escalation policies"}
  end

  defp process_response(_), do: {:error, "Invalid escalation policies response"}

  defp apply_callback(escalation_policies, options) do
    case Keyword.get(options, :callback) do
      nil -> %{escalation_policies: escalation_policies, options: options}
      callback -> callback.(escalation_policies, options)
    end
  end

  defp get_updated_options(options, _escalation_policies) do
    request_params = Keyword.get(options, :request_params, [])
    current_offset = Keyword.get(request_params, :offset, 0)
    next_offset = current_offset + 1
    updated_request_params = Keyword.put(request_params, :offset, next_offset)

    Keyword.put(options, :request_params, updated_request_params)
  end
end
