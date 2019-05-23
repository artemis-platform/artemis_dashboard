defmodule Artemis.Worker.PagerDutyIncidentSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 60_000,
    log_limit: 500,
    name: :pager_duty_incident_synchronizer

  import Artemis.Helpers

  require Logger

  alias Artemis.CreateManyIncidents
  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser
  alias Artemis.ListIncidents

  @default_start_date DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")
  @fetch_limit 500

  # Callbacks

  @impl true
  def call(_data, _meta) do
    user = GetSystemUser.call!()

    with {:ok, response} <- get_pager_duty_incidents(user),
         200  <- response.status_code,
         {:ok, incidents} <- process_response(response) do
      CreateManyIncidents.call(incidents, user)
    else
      {:skipped, message} -> {:skipped, message}
      {:error, message} -> {:error, message}
      error -> {:error, error}
    end
  rescue
    error ->
      Logger.info "Error synchronizing pager duty incidents: " <> inspect(error)
      {:error, "Exception raised while synchronizing incidents"}
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.get(:token)
    |> Artemis.Helpers.present?()
  end

  def get_pager_duty_incidents(user) do
    date = get_start_date(user)

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
        since: DateTime.to_iso8601(date),
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
      incident -> Timex.shift(incident.triggered_at, seconds: -1) # Include record in API response
    end
  end

  defp get_oldest_resolved_incident(user) do
    case get_incident_by("-triggered_at", %{status: ["resolved"]}, user) do
      nil -> nil
      incident -> Timex.shift(incident.triggered_at, seconds: 1) # Do not include record in API response
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
    Enum.map(incidents, fn (incident) ->
      severity = deep_get(incident, ["priority", "summary"]) || deep_get(incident, ["service", "summary"])
      triggered_at = incident
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

  def get_team_ids, do: Application.fetch_env!(:artemis, :pager_duty)[:team_ids]
end
