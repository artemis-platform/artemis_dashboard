defmodule Artemis.Drivers.PagerDuty.SynchronizeIncidents do
  alias Artemis.CreateManyIncidents
  alias Artemis.Drivers.PagerDuty
  alias Artemis.GetSystemUser
  alias Artemis.ListIncidents

  @moduledoc """
  Synchronize records from PagerDuty API to Artemis.Incident schema
  """

  @default_since_date DateTime.from_naive!(~N[2019-09-01 00:00:00], "Etc/UTC")

  def call(team_id) do
    system_user = GetSystemUser.call!()
    team_name = Artemis.Helpers.PagerDuty.get_pager_duty_team_name(team_id)

    options = [
      callback: callback_factory(team_id, team_name, system_user),
      request_params: get_request_params(team_id, system_user)
    ]

    PagerDuty.ListIncidents.call(options)
  end

  # Helpers

  defp get_request_params(team_id, user) do
    [
      "include[]": "acknowledgers",
      "include[]": "assignees",
      "include[]": "services",
      "include[]": "users",
      since: get_since_date(team_id, user),
      "team_ids[]": team_id
    ]
  end

  defp get_since_date(team_id, user) do
    team_id
    |> calculate_since_date(user)
    |> DateTime.to_iso8601()
  end

  defp callback_factory(team_id, team_name, user) do
    fn incidents, options ->
      filtered = filter_incidents(team_id, incidents, user)

      filtered_with_team_id =
        Enum.map(filtered, fn item ->
          item
          |> Map.put(:team_id, team_id)
          |> Map.put(:team_name, team_name)
        end)

      {:ok, _} = CreateManyIncidents.call(filtered_with_team_id, user)

      %{
        incidents: filtered,
        options: options
      }
    end
  end

  @doc """
  Find the oldest existing incident not in resolved status. If none exist,
  fallback to the default date.
  """
  def calculate_since_date(team_id, user) do
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
end
