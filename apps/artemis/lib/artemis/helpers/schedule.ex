defmodule Artemis.Helpers.Schedule do
  @moduledoc """
  Helper functions for Schedules

  Implemented using Cocktail: https://github.com/peek-travel/cocktail
  Documentation: https://hexdocs.pm/cocktail/
  """

  @doc """
  Encode Cocktail.Schedule struct as iCal string

  Takes an existing Cocktail.Schedule struct or a list of recurrence rules.
  """
  def encode(%Cocktail.Schedule{} = value) do
    Cocktail.Schedule.to_i_calendar(value)
  end

  def encode(value) when is_bitstring(value), do: value

  def encode(recurrence_rules) when is_list(recurrence_rules) do
    Timex.now()
    |> Cocktail.schedule()
    |> add_recurrence_rules(recurrence_rules)
    |> encode()
  end

  defp add_recurrence_rules(schedule, rules) do
    Enum.reduce(rules, schedule, fn rule, acc ->
      add_recurrence_rule(acc, rule)
    end)
  end

  defp add_recurrence_rule(schedule, rule) do
    frequency = get_recurrence_rule_frequency(rule)
    options = get_recurrence_rule_options(rule)

    Cocktail.Schedule.add_recurrence_rule(schedule, frequency, options)
  end

  defp get_recurrence_rule_frequency(rule) do
    rule
    |> Map.get("frequency", "daily")
    |> Artemis.Helpers.to_atom()
  end

  defp get_recurrence_rule_options(rule) do
    days =
      rule
      |> Map.get("days", [])
      |> Enum.map(&Artemis.Helpers.to_integer/1)

    {fallback_hour, fallback_minute} = parse_hours_and_minutes_from_time(rule)

    [
      days: days,
      hours: Map.get(rule, "hours", [fallback_hour]),
      minutes: Map.get(rule, "minutes", [fallback_minute]),
      seconds: Map.get(rule, "seconds", [0])
    ]
  end

  defp parse_hours_and_minutes_from_time(rule) do
    time =
      rule
      |> Map.get("time")
      |> String.pad_leading(5, "0")
      |> Timex.parse!("{h24}:{m}")

    {time.hour, time.minute}
  rescue
    _ -> {0, 0}
  end

  @doc """
  Decode iCal string as Cocktail.Schedule struct
  """
  def decode(value) when is_bitstring(value) do
    {:ok, result} = Cocktail.Schedule.from_i_calendar(value)

    result
  end

  def decode(value), do: value

  @doc """
  Return recurrence rules
  """
  def recurrence_rules(schedule) do
    schedule
    |> decode()
    |> Kernel.||(%{})
    |> Map.get(:recurrence_rules, [])
  end

  @doc """
  Return days of the week from recurrence rule
  """
  def days(schedule, options \\ []) do
    schedule
    |> get_schedule_recurrence_rule_validations(options)
    |> Artemis.Helpers.deep_get([:day, :days], [])
  end

  @doc """
  Return hours from recurrence rule
  """
  def hours(schedule, options \\ []) do
    schedule
    |> get_schedule_recurrence_rule_validations(options)
    |> Artemis.Helpers.deep_get([:hour_of_day, :hours], [])
  end

  @doc """
  Return hour from recurrence rule

  Note: assumes only one value for a given schedule recurrence rule
  """
  def hour(schedule, options \\ []) do
    schedule
    |> hours(options)
    |> List.first()
  end

  @doc """
  Return minutes from recurrence rule
  """
  def minutes(schedule, options \\ []) do
    schedule
    |> get_schedule_recurrence_rule_validations(options)
    |> Artemis.Helpers.deep_get([:minute_of_hour, :minutes], [])
  end

  @doc """
  Return minutes from recurrence rule

  Note: assumes only one value for a given schedule recurrence rule
  """
  def minute(schedule, options \\ []) do
    schedule
    |> minutes(options)
    |> List.first()
  end

  @doc """
  Return seconds from recurrence rule
  """
  def seconds(schedule, options \\ []) do
    schedule
    |> get_schedule_recurrence_rule_validations(options)
    |> Artemis.Helpers.deep_get([:second_of_minute, :seconds], [])
  end

  @doc """
  Return seconds from recurrence rule

  Note: assumes only one value for a given schedule recurrence rule
  """
  def second(schedule, options \\ []) do
    schedule
    |> seconds(options)
    |> List.first()
  end

  @doc """
  Humanize schedule value
  """
  def humanize(%Cocktail.Schedule{} = value) do
    value
    |> Cocktail.Schedule.to_string()
    |> String.replace("on  ", "on ")
    |> String.replace("on and", "on")
    |> String.replace(" on the 0th minute of the hour", "")
    |> String.replace(" on the 0th second of the minute", "")
  end

  def humanize(value) when is_bitstring(value) do
    value
    |> decode()
    |> humanize()
  end

  def humanize(nil), do: nil

  @doc """
  Returns the current scheduled date
  """
  def current(schedule, start_time \\ Timex.now())

  def current(%Cocktail.Schedule{} = schedule, start_time) do
    schedule
    |> Map.put(:start_time, start_time)
    |> Cocktail.Schedule.occurrences()
    |> Enum.take(1)
    |> hd()
  end

  def current(schedule, start_time) when is_bitstring(schedule) do
    current(decode(schedule), start_time)
  end

  @doc """
  Returns occurrences of the scheduled date
  """
  def occurrences(schedule, start_time \\ Timex.now(), count \\ 10)

  def occurrences(nil, _start_time, _count), do: []

  def occurrences(schedule, start_time, count) do
    schedule
    |> decode()
    |> Map.put(:start_time, start_time)
    |> Cocktail.Schedule.occurrences()
    |> Enum.take(count)
  end

  # Helpers

  defp get_schedule_recurrence_rule_validations(schedule, options) do
    index = Keyword.get(options, :index, 0)
    decoded_schedule = decode(schedule)

    if decoded_schedule do
      decoded_schedule
      |> Map.get(:recurrence_rules, [])
      |> Enum.at(index)
      |> Kernel.||(%{})
      |> Map.get(:validations, %{})
    end
  end
end
