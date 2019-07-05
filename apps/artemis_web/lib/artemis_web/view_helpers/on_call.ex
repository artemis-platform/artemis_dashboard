defmodule ArtemisWeb.ViewHelper.OnCall do
  use Phoenix.HTML

  @doc """
  Renders person currently on call.
  """
  def render_on_call_person(conn) do
    people =
      case Artemis.Worker.PagerDutyOnCallSynchronizer.get_result() do
        nil ->
          []

        data ->
          data
          |> Enum.filter(&(Map.get(&1, "escalation_level") == 1))
          |> Enum.map(&Artemis.Helpers.deep_get(&1, ["user", "summary"]))
          |> Enum.uniq()
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_person.html", conn: conn, people: people)
  end

  @doc """
  Renders current status as a colored dot and link to more information.
  """
  def render_on_call_status(conn, user) do
    by_status = Artemis.GetIncidentReports.call(%{reports: [:count_by_status]}, user).count_by_status

    color =
      cond do
        has_status?(by_status, "triggered") -> "red"
        has_status?(by_status, "acknowledged") -> "yellow"
        has_status?(by_status, "resolved") -> "green"
        true -> "gray"
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_status.html", conn: conn, color: color)
  end

  defp has_status?(report, status) do
    case Map.get(report, status) do
      nil -> false
      0 -> false
      _ -> true
    end
  end
end
