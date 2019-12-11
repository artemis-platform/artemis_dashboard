defmodule Artemis.Ecto.DateMacros do
  @doc """
  Returns a timestamp, truncated to the given precision.

  ## Usage Example

      Incident
      |> group_by([i], [date_trunc("month", i.triggered_at)])
      |> select([i], [date_trunc("month", i.triggered_at), count(i.id)])
      |> Repo.all()

  Returns:

      [
        [~N[1995-09-01 00:00:00.000000], 3]
        [~N[2019-09-01 00:00:00.000000], 3],
        [~N[2019-10-01 00:00:00.000000], 127],
        [~N[2019-11-01 00:00:00.000000], 7043],
        [~N[2019-12-01 00:00:00.000000], 83]
      ]

  ## Comparing `date_trunc` and `date_part`

  Where `date_trunc` returns: 

      [
        [~N[1995-09-01 00:00:00.000000], 3]
        [~N[2019-09-01 00:00:00.000000], 3],
        [~N[2019-10-01 00:00:00.000000], 127],
        [~N[2019-11-01 00:00:00.000000], 7043],
        [~N[2019-12-01 00:00:00.000000], 83]
      ]

  And `date_part` returns:

      [
        [9.0, 6],
        [10.0, 127],
        [11.0, 7043],
        [12.0, 82]
      ]

  Notice how `date_part` collapses results across years since it only returns
  the numeric `month` value as a float.

  Whereas, the `date_trunc` function preserves the difference between each year
  since it returns a truncated timestamp value.

  ## Precision Values

  Supported `precision` values include:

      microseconds
      milliseconds
      second
      minute
      hour
      day
      week
      month
      quarter
      year
      decade
      century
      millennium

  See: https://www.postgresql.org/docs/12/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC
  """
  defmacro date_trunc(precision, field) do
    quote do
      fragment("date_trunc(?, ?)", unquote(precision), unquote(field))
    end
  end

  @doc """
  Returns the part

  ## Usage Example

      Incident
      |> group_by([i], [date_trunc("month", i.triggered_at)])
      |> select([i], [date_trunc("month", i.triggered_at), count(i.id)])
      |> Repo.all()

  Returns:

      [
        [9.0, 6],
        [10.0, 127],
        [11.0, 7043],
        [12.0, 82]
      ]

  ## Comparing `date_trunc` and `date_part`

  See the documentation for `date_trunc/2`.

  ## Precision Values

  Supported `precision` values include:

      microseconds
      milliseconds
      second
      minute
      hour
      day
      week
      month
      quarter
      year
      decade
      century
      millennium

      dow
      doy
      epoch
      isodow
      isoyear
      timezone
      timezone_hour
      timezone_minute

  See: https://www.postgresql.org/docs/12/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT
  """
  defmacro date_part(precision, field) do
    quote do
      fragment("date_part(?, ?)", unquote(precision), unquote(field))
    end
  end
end
