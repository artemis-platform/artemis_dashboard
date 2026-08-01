defmodule ArtemisWeb.Print do
  @moduledoc """
  Date, time, and value formatting helpers.

  Ported from the original `ArtemisWeb.ViewHelper.Print`.

  Uses Elixir's built-in `Calendar` module instead of Timex for
  date/time formatting.

  ## Usage

      import ArtemisWeb.Print

      render_date(~U[2024-01-15 10:30:00Z])
      render_date_time(~U[2024-01-15 10:30:00Z])
      render_relative_time(~U[2024-01-15 10:30:00Z])
  """

  @default_timezone "America/New_York"

  @doc """
  Formats a date value.

  ## Examples

      iex> render_date(~U[2024-01-15 10:30:00Z])
      "January 15, 2024"
  """
  def render_date(value, opts \\ [])
  def render_date(nil, _opts), do: nil
  def render_date(0, _opts), do: nil

  def render_date(value, opts) when is_integer(value) do
    value
    |> DateTime.from_unix!()
    |> render_date(opts)
  end

  def render_date(%DateTime{} = value, opts) do
    tz = Keyword.get(opts, :timezone, @default_timezone)
    format = Keyword.get(opts, :format, :long)

    value
    |> shift_timezone(tz)
    |> format_date(format)
  rescue
    _ -> nil
  end

  def render_date(%Date{} = value, opts) do
    format = Keyword.get(opts, :format, :long)
    format_date(value, format)
  rescue
    _ -> nil
  end

  @doc """
  Formats a date and time value.

  ## Examples

      iex> render_date_time(~U[2024-01-15 10:30:00Z])
      "January 15, 2024 at 5:30 AM EST"
  """
  def render_date_time(value, opts \\ [])
  def render_date_time(nil, _opts), do: nil
  def render_date_time(0, _opts), do: nil

  def render_date_time(value, opts) when is_integer(value) do
    value
    |> DateTime.from_unix!()
    |> render_date_time(opts)
  end

  def render_date_time(%DateTime{} = value, opts) do
    tz = Keyword.get(opts, :timezone, @default_timezone)
    include_seconds = Keyword.get(opts, :seconds, false)

    dt = shift_timezone(value, tz)

    date_part = format_date(dt, :long)
    time_part = format_time(dt, include_seconds)
    tz_abbr = timezone_abbr(dt)

    "#{date_part} at #{time_part} #{tz_abbr}"
  rescue
    _ -> nil
  end

  @doc """
  Formats a time-only value.

  ## Examples

      iex> render_time(~U[2024-01-15 10:30:45Z])
      "5:30:45 AM EST"
  """
  def render_time(value, opts \\ [])
  def render_time(nil, _opts), do: nil
  def render_time(0, _opts), do: nil

  def render_time(value, opts) when is_integer(value) do
    value
    |> DateTime.from_unix!()
    |> render_time(opts)
  end

  def render_time(%DateTime{} = value, opts) do
    tz = Keyword.get(opts, :timezone, @default_timezone)

    dt = shift_timezone(value, tz)
    time_part = format_time(dt, true)
    tz_abbr = timezone_abbr(dt)

    "#{time_part} #{tz_abbr}"
  rescue
    _ -> nil
  end

  @doc """
  Formats a relative time string, e.g. "3 minutes ago".
  """
  def render_relative_time(value)
  def render_relative_time(nil), do: nil
  def render_relative_time(0), do: nil

  def render_relative_time(value) when is_integer(value) do
    value
    |> DateTime.from_unix!()
    |> render_relative_time()
  end

  def render_relative_time(%DateTime{} = value) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, value)

    cond do
      diff_seconds < 0 -> "just now"
      diff_seconds < 60 -> "#{diff_seconds} seconds ago"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} minutes ago"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)} hours ago"
      diff_seconds < 2_592_000 -> "#{div(diff_seconds, 86400)} days ago"
      true -> render_date(value)
    end
  rescue
    _ -> nil
  end

  @doc """
  Formats a duration between two DateTimes as a human-readable string.

  ## Examples

      iex> render_time_duration(~U[2024-01-15 10:00:00Z], ~U[2024-01-15 11:30:45Z])
      "1 hour, 30 minutes, 45 seconds"
  """
  def render_time_duration(first, second) do
    diff_seconds = abs(DateTime.diff(second, first))
    render_time_humanized(diff_seconds)
  end

  @doc """
  Formats a number of seconds as a human-readable duration.

  ## Examples

      iex> render_time_humanized(3661)
      "1 hour, 1 minute, 1 second"
  """
  def render_time_humanized(total_seconds) when is_integer(total_seconds) and total_seconds > 0 do
    days = div(total_seconds, 86400)
    remaining = rem(total_seconds, 86400)
    hours = div(remaining, 3600)
    remaining = rem(remaining, 3600)
    minutes = div(remaining, 60)
    seconds = rem(remaining, 60)

    parts =
      []
      |> maybe_add_part(days, "day")
      |> maybe_add_part(hours, "hour")
      |> maybe_add_part(minutes, "minute")
      |> maybe_add_part(seconds, "second")
      |> Enum.reverse()

    case parts do
      [] -> "< 1 second"
      _ -> Enum.join(parts, ", ")
    end
  end

  def render_time_humanized(_), do: "< 1 second"

  @doc """
  Converts newline characters to `<br>` tags.
  """
  def new_line_to_line_break(value) when is_binary(value) do
    value
    |> String.split("\n", trim: false)
    |> Enum.intersperse(Phoenix.HTML.raw("<br/>"))
  end

  def new_line_to_line_break(value), do: value

  @doc """
  Pretty-prints a JSON-compatible value.
  """
  def pretty_print_json(value) when is_map(value) do
    Jason.encode!(value, pretty: true)
  end

  def pretty_print_json(value), do: value

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp shift_timezone(datetime, tz) do
    DateTime.shift_zone!(datetime, tz)
  rescue
    _ -> datetime
  end

  @months ~w(January February March April May June July August September October November December)

  defp format_date(dt, :long) do
    month = Enum.at(@months, dt.month - 1)
    "#{month} #{dt.day}, #{dt.year}"
  end

  defp format_date(dt, :short) do
    month = dt.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = dt.day |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{dt.year}-#{month}-#{day}"
  end

  defp format_time(dt, include_seconds) do
    {hour_12, ampm} = to_12_hour(dt.hour)
    minute = dt.minute |> Integer.to_string() |> String.pad_leading(2, "0")

    if include_seconds do
      second = dt.second |> Integer.to_string() |> String.pad_leading(2, "0")
      "#{hour_12}:#{minute}:#{second} #{ampm}"
    else
      "#{hour_12}:#{minute} #{ampm}"
    end
  end

  defp to_12_hour(0), do: {12, "AM"}
  defp to_12_hour(12), do: {12, "PM"}
  defp to_12_hour(hour) when hour < 12, do: {hour, "AM"}
  defp to_12_hour(hour), do: {hour - 12, "PM"}

  defp timezone_abbr(%DateTime{} = dt) do
    dt.zone_abbr || "UTC"
  end

  defp maybe_add_part(parts, 0, _unit), do: parts
  defp maybe_add_part(parts, 1, unit), do: ["1 #{unit}" | parts]
  defp maybe_add_part(parts, n, unit), do: ["#{n} #{unit}s" | parts]
end
