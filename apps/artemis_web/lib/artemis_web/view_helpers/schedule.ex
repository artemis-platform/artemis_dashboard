defmodule ArtemisWeb.ViewHelper.Schedule do
  use Phoenix.HTML

  @doc """
  Return the schedule days for a specific recurrence rule
  """
  def get_schedule_days(schedule, index, default \\ nil) do
    days = Artemis.Helpers.Schedule.days(schedule, index: index)

    case days && length(days) > 0 do
      true -> days
      _ -> default
    end
  end

  @doc """
  Return the schedule time for a specific recurrence rule
  """
  def get_schedule_time(schedule, index, default \\ nil) do
    hour = Artemis.Helpers.Schedule.hour(schedule, index: index)

    minute =
      schedule
      |> Artemis.Helpers.Schedule.minute(index: index)
      |> Artemis.Helpers.to_string()
      |> String.pad_leading(2, "0")

    case is_nil(hour) do
      true -> default
      _ -> "#{hour}:#{minute}"
    end
  end

  @doc """
  Print schedule summary
  """
  def get_schedule_summary(schedule) do
    rules =
      schedule
      |> Artemis.Helpers.Schedule.humanize()
      |> Artemis.Helpers.to_string()
      |> String.split("/")

    content_tag(:ul, class: "schedule-summary") do
      Enum.map(rules, &content_tag(:li, &1))
    end
  end

  @doc """
  Print schedule occurrences
  """
  def get_schedule_occurrences(schedule, start_time \\ Timex.now(), count \\ 10) do
    format = "{WDfull}, {Mfull} {D}, {YYYY} at {h12}:{m}{am} {Zabbr}"

    occurrences =
      schedule
      |> Artemis.Helpers.Schedule.occurrences(start_time, count)
      |> Enum.map(&ArtemisWeb.ViewHelper.Print.render_date_time(&1, format))

    content_tag(:ul, class: "schedule-occurrences") do
      Enum.map(occurrences, &content_tag(:li, &1, class: "no-wrap"))
    end
  end
end
