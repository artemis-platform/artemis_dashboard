defmodule ArtemisWeb.ViewHelper.Print do
  use Phoenix.HTML

  @doc """
  Convert `\n` new lines to <br/> tags
  """
  def new_line_to_line_break(values) when is_list(values) do
    values
    |> Enum.map(&new_line_to_line_break/1)
    |> Enum.join()
  end

  def new_line_to_line_break(value) when is_bitstring(value) do
    value
    |> String.split("\n", trim: false)
    |> Enum.intersperse(Phoenix.HTML.Tag.tag(:br))
  end

  def new_line_to_line_break(value), do: value

  @doc """
  Print date in human readable format
  """
  def render_date(value, format \\ "{Mfull} {D}, {YYYY}")

  def render_date(nil, _format), do: nil

  def render_date(0, _format), do: nil

  def render_date(value, format) when is_number(value) do
    value
    |> from_unix()
    |> render_date(format)
  end

  def render_date(value, format) do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  rescue
    _ -> nil
  end

  @doc """
  Print date in human readable format
  """
  def render_date_time(value, format \\ "{Mfull} {D}, {YYYY} at {h12}:{m}{am} {Zabbr}")

  def render_date_time(nil, _format), do: nil

  def render_date_time(0, _format), do: nil

  def render_date_time(value, format) when is_number(value) do
    value
    |> from_unix()
    |> render_date_time(format)
  end

  def render_date_time(value, format) do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  rescue
    _ -> nil
  end

  @doc """
  Print date in human readable format with seconds
  """
  def render_date_time_with_seconds(value, format \\ "{Mfull} {D}, {YYYY} at {h12}:{m}:{s}{am} {Zabbr}")

  def render_date_time_with_seconds(nil, _format), do: nil

  def render_date_time_with_seconds(0, _format), do: nil

  def render_date_time_with_seconds(value, format) when is_number(value) do
    value
    |> from_unix()
    |> render_date_time_with_seconds(format)
  end

  def render_date_time_with_seconds(value, format) do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  rescue
    _ -> nil
  end

  @doc """
  Print date in IS8601 format with seconds
  """
  def render_date_time_with_seconds_short(value) do
    render_date_time_with_seconds(value, "{Mshort} {D}, {YYYY} {h12}:{m}:{s}{am} {Zabbr}")
  end

  @doc """
  Print date in IS8601 format with seconds
  """
  def render_date_time_with_seconds_shorter(value) do
    render_date_time_with_seconds(value, "{YYYY}-{0M}-{0D} {h12}:{m}:{s}{am} {Zabbr}")
  end

  @doc """
  Print time in human readable format with seconds
  """
  def render_time(value, format \\ "{h12}:{m}:{s}{am} {Zabbr}")

  def render_time(nil, _format), do: nil

  def render_time(0, _format), do: nil

  def render_time(value, format) when is_number(value) do
    value
    |> from_unix()
    |> render_time(format)
  end

  def render_time(value, format) do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  rescue
    _ -> nil
  end

  @doc """
  Print date in relative time, e.g. "3 minutes ago"
  """
  def render_relative_time(value, format \\ "{relative}")

  def render_relative_time(nil, _format), do: nil

  def render_relative_time(0, _format), do: nil

  def render_relative_time(value, format) when is_number(value) do
    value
    |> from_unix()
    |> render_relative_time(format)
  end

  def render_relative_time(value, format) do
    Timex.format!(value, format, :relative)
  rescue
    _ -> nil
  end

  @doc """
  Returns a humanized value of elapsed time between two dates
  """
  def render_time_duration(first, second) do
    diff_in_seconds =
      second
      |> Timex.diff(first)
      |> div(1_000_000)

    render_time_humanized(diff_in_seconds)
  end

  @doc """
  Returns a humanized value
  """
  def render_time_humanized(seconds) do
    duration = Timex.Duration.from_seconds(seconds)

    case Timex.Duration.to_microseconds(duration) > 0 do
      true -> Timex.Format.Duration.Formatters.Humanized.format(duration)
      false -> "< 1 second"
    end
  end

  @doc """
  Encodes JSON compatable data into a pretty printed string
  """
  def pretty_print_json_into_textarea(form, key) do
    form
    |> input_value(key)
    |> pretty_print_value()
  end

  defp pretty_print_value(value) when is_map(value), do: Jason.encode!(value, pretty: true)
  defp pretty_print_value(value), do: value

  # Helpers

  def from_unix(value) when is_float(value), do: from_unix(trunc(value))
  def from_unix(value), do: Timex.from_unix(value)
end
