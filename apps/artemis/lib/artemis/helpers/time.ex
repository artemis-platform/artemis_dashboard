defmodule Artemis.Helpers.Time do
  @doc """
  Return the beginning of the day
  """
  def beginning_of_day(time \\ Timex.now()) do
    Timex.beginning_of_day(time)
  end

  @doc """
  Return the beginning of the next day
  """
  def get_next_day(time \\ Timex.now()) do
    time
    |> Timex.shift(days: 1)
    |> beginning_of_day()
  end

  @doc """
  Return the closest whole day
  """
  def get_closest_day(time \\ Timex.now()) do
    case time.hour >= 12 do
      true -> get_next_day(time)
      false -> beginning_of_day(time)
    end
  end

  @doc """
  Return milliseconds from given time. If a time is not passed, current
  timestamp is used.
  """
  def get_milliseconds_to_next_day(time \\ Timex.now()) do
    time
    |> get_next_day()
    |> Timex.diff(time, :microseconds)
    |> Kernel./(1000)
    |> ceil()
  end

  @doc """
  Return the beginning of the hour
  """
  def beginning_of_hour(time \\ Timex.now()) do
    time
    |> Map.put(:second, 0)
    |> Map.put(:minute, 0)
    |> DateTime.truncate(:second)
  end

  @doc """
  Return the beginning of the next hour
  """
  def get_next_hour(time \\ Timex.now()) do
    time
    |> Timex.shift(hours: 1)
    |> beginning_of_hour()
  end

  @doc """
  Return the closest whole hour
  """
  def get_closest_hour(time \\ Timex.now()) do
    case time.minute >= 30 do
      true -> get_next_hour(time)
      false -> beginning_of_hour(time)
    end
  end

  @doc """
  Return milliseconds from given time. If a time is not passed, current
  timestamp is used.
  """
  def get_milliseconds_to_next_hour(time \\ Timex.now()) do
    time
    |> get_next_hour()
    |> Timex.diff(time, :microseconds)
    |> Kernel./(1000)
    |> ceil()
  end

  @doc """
  Return the beginning of the minute
  """
  def beginning_of_minute(time \\ Timex.now()) do
    time
    |> Map.put(:second, 0)
    |> DateTime.truncate(:second)
  end

  @doc """
  Return the beginning of the next minute
  """
  def get_next_minute(time \\ Timex.now()) do
    time
    |> Timex.shift(minutes: 1)
    |> beginning_of_minute()
  end

  @doc """
  Return the closest whole minute
  """
  def get_closest_minute(time \\ Timex.now()) do
    case time.second >= 30 do
      true -> get_next_minute(time)
      false -> beginning_of_minute(time)
    end
  end

  @doc """
  Return the beginning of the second
  """
  def beginning_of_second(time \\ Timex.now()) do
    time
    |> Map.put(:millisecond, 0)
    |> DateTime.truncate(:millisecond)
  end

  @doc """
  Return the beginning of the next second
  """
  def get_next_second(time \\ Timex.now()) do
    time
    |> Timex.shift(seconds: 1)
    |> beginning_of_second()
  end

  @doc """
  Return milliseconds from given time. If a time is not passed, current
  timestamp is used.
  """
  def get_milliseconds_to_next_minute(time \\ Timex.now()) do
    time
    |> get_next_minute()
    |> Timex.diff(time, :microseconds)
    |> Kernel./(1000)
    |> ceil()
  end

  @doc """
  Return milliseconds from given time. If a time is not passed, current
  timestamp is used.
  """
  def get_milliseconds_to_next_second(time \\ Timex.now()) do
    time
    |> get_next_second()
    |> Timex.diff(time, :microseconds)
    |> Kernel./(1000)
    |> ceil()
  end

  @doc """
  Convert milliseconds to a human readable string
  """
  def humanize_milliseconds(value) do
    value
    |> Timex.Duration.from_milliseconds()
    |> Timex.Format.Duration.Formatters.Humanized.format()
  end

  @doc """
  Convert seconds to a human readable string
  """
  def humanize_seconds(value) do
    value
    |> Timex.Duration.from_seconds()
    |> Timex.Format.Duration.Formatters.Humanized.format()
  end

  @doc """
  Print humanized datetime
  """
  def humanize_datetime(value, format \\ "{Mfull} {D}, {YYYY} {h12}:{m}:{s}{am} {Zabbr}") do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  rescue
    _ -> nil
  end
end
