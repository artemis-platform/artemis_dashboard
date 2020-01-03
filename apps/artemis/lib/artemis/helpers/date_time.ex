defmodule Artemis.Helpers.DateTime do

  @doc """
  Adds microseconds to an existing DateTime:

      #DateTime<2020-01-03 19:25:05Z>
      #DateTime<2020-01-03 19:25:05.000000Z>
  
  Also works on NaiveDateTimes:

      ~N[2020-01-03 19:30:00]
      ~N[2020-01-03 19:30:00.000000]
  
  """
  def add_microseconds(date_time, value \\ 0, precision \\ 6) do
    %{date_time | microsecond: {value, precision}}
  end
end
