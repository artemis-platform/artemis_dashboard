defmodule Artemis.ListIncidentReports do
  use Artemis.Context
  use Artemis.ContextReport

  use Artemis.ContextCache,
    cache_reset_on_cloudant_changes: [
      %{schema: Artemis.Incident, action: "create"},
      %{schema: Artemis.Incident, action: "delete"},
      %{schema: Artemis.Incident, action: "update"}
    ],
    cache_reset_on_events: [
      "incident:created",
      "incident:deleted",
      "incident:deleted:all",
      "incident:updated"
    ]

  import Artemis.Ecto.DateMacros
  import Ecto.Query

  alias Artemis.Incident
  alias Artemis.Repo

  def call(reports \\ [], params \\ %{}, user) do
    get_reports(reports, params, user)
  end

  # Callbacks

  @impl true
  def get_allowed_reports(_user) do
    [
      :count_by_team_id_and_service_name_and_day_of_week
    ]
  end

  @impl true
  def get_report(:count_by_team_id_and_service_name_and_day_of_week, params, _user) do
    Incident
    |> maybe_where_start_date(params)
    |> maybe_where_end_date(params)
    |> group_by([i], [i.team_id, i.service_name, date_part("isodow", i.triggered_at)])
    |> select([i], [max(i.team_id), max(i.service_name), date_part("isodow", i.triggered_at), count(i.id)])
    |> Repo.all()
  end

  # Helpers

  defp maybe_where_start_date(query, %{start_date: start_date}) do
    where(query, [i], i.triggered_at >= ^start_date)
  end

  defp maybe_where_start_date(query, _params), do: query

  defp maybe_where_end_date(query, %{end_date: end_date}) do
    where(query, [i], i.triggered_at < ^end_date)
  end

  defp maybe_where_end_date(query, _params), do: query
end
