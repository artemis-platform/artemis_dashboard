defmodule Artemis.Worker.PagerDutyIncidentSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 60_000,
    log_limit: 500,
    name: :pager_duty_incident_synchronizer

  import Artemis.Helpers

  alias Artemis.CreateManyIncidents
  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser
  alias Artemis.ListIncidents

  defmodule Data do
    defstruct [
      :meta,
      :result
    ]
  end

  @default_start_date DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")
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

  # Callbacks

  @impl true
  def call(data), do: fetch_data(data)

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:pager_duty_synchronize_incidents)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp fetch_data(data, options \\ []) do
    with user <- GetSystemUser.call!(),
         {:ok, response} <- get_pager_duty_incidents(user, options),
         200 <- response.status_code,
         {:ok, incidents} <- process_response(response),
         {:ok, filtered} <- filter_incidents(incidents, user),
         {:ok, result} <- CreateManyIncidents.call(filtered, user) do
      total = Map.get(result, :total) + Keyword.get(options, :total, 0)
      more? = deep_get(response, [:body, "more"])

      case more? do
        false ->
          meta = [api_response: response]
          data = create_data(total, meta)
          {:ok, data}

        true ->
          date =
            incidents
            |> Enum.map(& &1.triggered_at)
            |> Enum.sort()
            |> hd()

          options =
            options
            |> Keyword.put(:since, date)
            |> Keyword.put(:total, total)

          fetch_data(data, options)
      end
    else
      {:skipped, message} -> {:skipped, message}
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    error ->
      Logger.info("Error synchronizing pager duty incidents: " <> inspect(error))
      {:error, "Exception raised while synchronizing incidents"}
  end

  defp create_data(result, meta) do
    %Data{
      meta: Enum.into(meta, %{}),
      result: result
    }
  end

  defp get_pager_duty_incidents(user, options) do
    date =
      case Keyword.get(options, :since) do
        nil -> DateTime.to_iso8601(get_start_date(user))
        date -> date
      end

    path = "/incidents"
    headers = []

    options = [
      params: [
        "include[]": "acknowledgers",
        "include[]": "assignees",
        "include[]": "services",
        "include[]": "users",
        limit: @fetch_limit,
        offset: 0,
        since: date,
        "team_ids[]": get_team_ids()
      ]
    ]

    PagerDuty.get(path, headers, options)
  end

  @doc """
  Find the oldest existing incident not in resolved status. If none exist,
  fallback to the default date.
  """
  def get_start_date(user, default_start_date \\ @default_start_date) do
    with nil <- get_earliest_unresolved_incident(user),
         nil <- get_oldest_resolved_incident(user) do
      default_start_date
    else
      date -> date
    end
  end

  defp get_earliest_unresolved_incident(user) do
    case get_incident_by("triggered_at", %{status: ["triggered", "acknowledged"]}, user) do
      nil -> nil
      # Include record in API response
      incident -> Timex.shift(incident.triggered_at, seconds: -1)
    end
  end

  defp get_oldest_resolved_incident(user) do
    case get_incident_by("-triggered_at", %{status: ["resolved"]}, user) do
      nil -> nil
      # Do not include record in API response
      incident -> Timex.shift(incident.triggered_at, seconds: 1)
    end
  end

  defp get_incident_by(order, filters, user) do
    params = %{
      filters: filters,
      order: order,
      paginate: true
    }

    with results <- ListIncidents.call(params, user),
         true <- is_map(results),
         true <- results.total_entries > 1 do
      hd(results.entries)
    else
      _ -> nil
    end
  end

  defp process_response(%HTTPoison.Response{body: %{"incidents" => incidents}}) do
    case length(incidents) do
      0 -> {:skipped, "No new records to sync"}
      _ -> {:ok, process_response_entries(incidents)}
    end
  end

  defp process_response_entries(incidents) do
    Enum.map(incidents, fn incident ->
      severity = deep_get(incident, ["priority", "summary"]) || deep_get(incident, ["service", "summary"])

      triggered_at =
        incident
        |> Map.get("created_at")
        |> Timex.parse!("{ISO:Extended}")

      %{
        acknowledged_at: nil,
        acknowledged_by: nil,
        description: nil,
        meta: incident,
        resolved_at: nil,
        resolved_by: nil,
        severity: severity,
        source: "pagerduty",
        source_uid: Map.get(incident, "id"),
        status: Map.get(incident, "status"),
        title: Map.get(incident, "title"),
        triggered_at: triggered_at,
        triggered_by: nil
      }
    end)
  end

  # Filter out updates to existing incidents that are already resolved
  defp filter_incidents(incidents, user) do
    resolved_incidents = get_existing_resolved_incidents(user)

    filtered =
      Enum.reject(incidents, fn incident ->
        Enum.member?(resolved_incidents, incident.source_uid)
      end)

    {:ok, filtered}
  end

  defp get_existing_resolved_incidents(user) do
    %{filters: %{status: "resolved"}}
    |> ListIncidents.call(user)
    |> Enum.map(& &1.source_uid)
  end

  def get_team_ids, do: Application.fetch_env!(:artemis, :pager_duty)[:team_ids]
end
