defmodule ArtemisWeb.OnCallController do
  use ArtemisWeb, :controller

  @date_format "{YYYY}-{0M}-{0D}"

  def index(conn, _params) do
    authorize_any(conn, ["incidents:list"], fn ->
      render(conn, "index.html")
    end)
  end

  def index_weekly_summary(conn, params) do
    authorize_any(conn, ["incidents:list"], fn ->
      start_date = get_start_date(params)
      end_date = get_end_date(start_date)
      next_week_date = get_next_week_date(start_date)
      previous_week_date = get_previous_week_date(start_date)

      assigns = [
        end_date: end_date,
        next_week: next_week_date,
        previous_week: previous_week_date,
        start_date: start_date
      ]

      render(conn, "index_weekly_summary.html", assigns)
    end)
  end

  # Helpers

  defp get_start_date(params) do
    params
    |> Map.get("start")
    |> Timex.parse!(@date_format)
    |> Timex.to_datetime("UTC")
  rescue
    _ -> Timex.beginning_of_week(Timex.now())
  end

  defp get_end_date(start_date) do
    Timex.end_of_week(start_date)
  end

  defp get_next_week_date(start_date) do
    start_date
    |> Timex.shift(days: 7)
    |> Timex.format!(@date_format)
  end

  defp get_previous_week_date(start_date) do
    start_date
    |> Timex.shift(days: -7)
    |> Timex.format!(@date_format)
  end
end
