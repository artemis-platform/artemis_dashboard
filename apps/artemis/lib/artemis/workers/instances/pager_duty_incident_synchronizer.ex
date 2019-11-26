defmodule Artemis.Worker.PagerDutyIncidentSynchronizer do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: :timer.hours(6),
    delayed_start: :timer.hours(6),
    name: :pager_duty_incident_synchronizer

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

  @default_since_date DateTime.from_naive!(~N[2019-09-01 00:00:00], "Etc/UTC")

  # Callbacks

  @impl true
  def call(_data, _config) do
    system_user = GetSystemUser.call!()

    synchronize_incidents(system_user)
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:pager_duty_synchronize_incidents)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp synchronize_incidents(user) do
    team_ids = [
      "PTS5TEF",
      "PENNR50",
      "PHJYRHQ"
    ]

    results =
      Enum.reduce(team_ids, %{}, fn team_id, acc ->
        {:ok, result} = synchronize_incidents_for_team(team_id, user)

        total = length(result.data)

        Map.put(acc, team_id, total)
      end)

    %Data{
      result: results
    }
  end

  defp synchronize_incidents_for_team(team_id, user) do
    since_date = DateTime.to_iso8601(get_since_date(team_id, user))

    request_params = [
      "include[]": "acknowledgers",
      "include[]": "assignees",
      "include[]": "services",
      "include[]": "users",
      since: since_date,
      # "statuses[]": "acknowledged",
      # "statuses[]": "resolved",
      # "statuses[]": "triggered",
      "team_ids[]": team_id
    ]

    callback = fn incidents, options ->
      filtered = filter_incidents(team_id, incidents, user)
      filtered_with_team_id = Enum.map(filtered, &Map.put(&1, :team_id, team_id))

      {:ok, _} = CreateManyIncidents.call(filtered_with_team_id, user)

      %{
        incidents: filtered,
        options: options
      }
    end

    options = [
      callback: callback,
      request_params: request_params
    ]

    PagerDuty.ListIncidents.call(options)
  end

  @doc """
  Find the oldest existing incident not in resolved status. If none exist,
  fallback to the default date.
  """
  def get_since_date(team_id, user) do
    with nil <- get_earliest_unresolved_incident(team_id, user),
         nil <- get_oldest_resolved_incident(team_id, user) do
      @default_since_date
    else
      date -> date
    end
  end

  defp get_earliest_unresolved_incident(team_id, user) do
    filters = %{
      status: ["triggered", "acknowledged"],
      team_id: team_id
    }

    case get_incident_by("triggered_at", filters, user) do
      nil -> nil
      # Include record in API response
      incident -> Timex.shift(incident.triggered_at, seconds: -1)
    end
  end

  defp get_oldest_resolved_incident(team_id, user) do
    filters = %{
      status: ["resolved"],
      team_id: team_id
    }

    case get_incident_by("-triggered_at", filters, user) do
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

  # Filter out updates to existing incidents that are already resolved
  defp filter_incidents(team_id, incidents, user) do
    resolved_incidents = get_existing_resolved_incidents(team_id, user)

    Enum.reject(incidents, fn incident ->
      Enum.member?(resolved_incidents, incident.source_uid)
    end)
  end

  defp get_existing_resolved_incidents(team_id, user) do
    filters = %{
      status: ["resolved"],
      team_id: team_id
    }

    %{filters: filters}
    |> ListIncidents.call(user)
    |> Enum.map(& &1.source_uid)
  end

  # TODO: update
  defp get_team_ids, do: Application.fetch_env!(:artemis, :pager_duty)[:team_ids]
end
