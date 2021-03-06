defmodule Artemis.Drivers.PagerDuty.ListIncidents do
  require Logger

  alias Artemis.Drivers.PagerDuty

  defmodule Result do
    defstruct data: [],
              meta: %{}
  end

  @moduledoc """
  Fetches incidents from the PagerDuty API.

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
    :since
    :until
    :request_headers
    :request_params
    :request_path

  """

  # Warning!
  #
  # As of 2019/05 the PagerDuty API endpoint contains a critical bugs.
  #
  # The documentation states the maximum `limit` value is 100. Anything higher
  # than 100 automatically gets rounded down to 100.
  #
  # This alone isn't a problem, except for there are additional undocumented
  # constraints that do cause problems.
  #
  # The actual constraint is `limit` plus `offset`. Once the combined value
  # reached `100` pagination stops working and no further records will be returned.
  # This includes the `more` key which will always return `false` once the
  # constraint is hit.
  #
  # Finally, a more minor issue is the `total` value cannot be trusted. When
  # explicitly passing `total: true` as a parameter, the return value for `total`
  # is frequently incorrect.
  @fetch_limit 99
  @request_path "/incidents"

  def call(options \\ []) do
    initial_data = %Result{
      data: [],
      meta: %{}
    }

    fetch_data(initial_data, options)
  end

  defp fetch_data(acc, options) do
    with {:ok, response} <- get_page(options),
         %HTTPoison.Response{status_code: 200} <- response,
         {:ok, all_incidents} <- process_response(response) do
      callback_results = apply_callback(all_incidents, options)

      incidents = Map.get(callback_results, :incidents, all_incidents)
      options = Map.get(callback_results, :options, options)

      acc =
        acc
        |> Map.update!(:data, &Kernel.++(&1, incidents))
        |> Map.update!(:meta, &Map.put(&1, :api_response, response))

      more? = Artemis.Helpers.deep_get(response, [:body, "more"], false)

      case more? do
        false -> {:ok, get_unique_results(acc)}
        true -> fetch_data(acc, get_updated_options(options, all_incidents))
      end
    else
      {:error, %HTTPoison.Error{id: nil, reason: :closed}} ->
        fetch_data(acc, options)

      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        fetch_data(acc, options)

      %HTTPoison.Response{} = response ->
        log_data = Map.take(response, [:body, :request_url, :status_code])
        Logger.info("Error fetching incidents from PagerDuty API: " <> inspect(log_data))

        return_error(response.status_code)

      error ->
        Logger.info("Error fetching incidents from PagerDuty API: " <> inspect(error))

        return_error(error)
    end
  rescue
    error ->
      Logger.info("Error fetching incidents from PagerDuty API: " <> inspect(error))

      {:error, "Exception raised while fetching incidents from PagerDuty API"}
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
      offset: 0,
      since: get_default_since_date(),
      until: get_default_until_date()
    ]

    custom_request_params = Keyword.get(options, :request_params, [])

    Keyword.merge(default_request_params, custom_request_params)
  end

  defp get_default_since_date() do
    Timex.now()
    |> Timex.shift(months: -5)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp get_default_until_date() do
    Timex.now()
    |> Timex.shift(hours: 1)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp process_response(%HTTPoison.Response{body: %{"incidents" => incidents}}) do
    case length(incidents) do
      0 -> {:ok, []}
      _ -> {:ok, process_response_entries(incidents)}
    end
  end

  defp process_response(response), do: return_error(response)

  defp process_response_entries(incidents) do
    Enum.map(incidents, fn incident ->
      urgency = Artemis.Helpers.deep_get(incident, ["urgency"])
      priority_summary = Artemis.Helpers.deep_get(incident, ["priority", "summary"])
      service_id = Artemis.Helpers.deep_get(incident, ["service", "id"])
      service_name = Artemis.Helpers.deep_get(incident, ["service", "name"])
      severity = urgency || priority_summary || service_name

      triggered_at =
        incident
        |> Map.get("created_at")
        |> Timex.parse!("{ISO:Extended}")

      acknowledgement =
        incident
        |> Map.get("acknowledgements", [])
        |> List.first()

      acknowledged_at =
        case Map.get(acknowledgement || %{}, "at") do
          nil -> nil
          date -> Timex.parse!(date, "{ISO:Extended}")
        end

      acknowledged_by = Map.get(acknowledgement || %{}, "name")

      %{
        acknowledged_at: acknowledged_at,
        acknowledged_by: acknowledged_by,
        description: Map.get(incident, "summary"),
        meta: incident,
        resolved_at: nil,
        resolved_by: nil,
        service_id: service_id,
        service_name: service_name,
        severity: severity,
        source: "pagerduty",
        source_uid: Map.get(incident, "id"),
        status: Map.get(incident, "status"),
        team_id: nil,
        team_name: nil,
        title: Map.get(incident, "title"),
        triggered_at: triggered_at,
        triggered_by: nil
      }
    end)
  end

  defp apply_callback(incidents, options) do
    case Keyword.get(options, :callback) do
      nil -> %{incidents: incidents, options: options}
      callback -> callback.(incidents, options)
    end
  end

  defp get_updated_options(options, incidents) do
    since_date =
      incidents
      |> Enum.map(& &1.triggered_at)
      |> Artemis.Helpers.DateTime.sort_by_date_time()
      |> List.last()
      |> DateTime.to_iso8601()

    request_params = Keyword.get(options, :request_params, [])
    updated_request_params = Keyword.put(request_params, :since, since_date)

    Keyword.put(options, :request_params, updated_request_params)
  end

  defp get_unique_results(acc) do
    Map.update!(acc, :data, fn data ->
      Enum.uniq_by(data, & &1.source_uid)
    end)
  end

  defp return_error({:error, message}), do: {:error, message}
  defp return_error(error), do: {:error, error}
end
