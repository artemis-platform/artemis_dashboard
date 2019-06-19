defmodule Artemis.GetIncidentReports do
  alias Artemis.Incident
  alias Artemis.Repo

  import Ecto.Query

  @allowed_reports [
    :count_by_status
  ]

  def call(params, user) do
    params
    |> filter_requested_reports
    |> get_reports(params, user)
  end

  defp filter_requested_reports(params) do
    params
    |> Map.get(:reports, [])
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(@allowed_reports))
    |> MapSet.to_list()
  end

  defp get_reports(requested, _, _) when requested == [], do: %{}

  defp get_reports(requested, params, user) do
    requested
    |> gather_reports(params, user)
    |> execute_reports
  end

  defp gather_reports(requested, params, user) do
    Enum.reduce(requested, %{}, fn key, acc ->
      value = fn ->
        get_report(key, params, user)
      end

      Map.put(acc, key, value)
    end)
  end

  defp execute_reports(reports) do
    Artemis.Helpers.async_await_many(reports)
  end

  # Reports

  defp get_report(:count_by_status, _params, _user) do
    Incident
    |> group_by([i], [i.status])
    |> select([i], [i.status, count(i.id)])
    |> Repo.all()
    |> Enum.reduce(%{}, &Map.put(&2, Enum.at(&1, 0), Enum.at(&1, 1)))
  end
end
