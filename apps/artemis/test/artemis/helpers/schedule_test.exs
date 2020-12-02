defmodule Artemis.Helpers.ScheduleTest do
  use Artemis.DataCase

  alias Artemis.Helpers.Schedule

  @timestamp ~U[2020-01-01 12:00:00Z]

  setup do
    options = [
      days: [0, 1, 2, 3, 4, 5, 6],
      hours: [12],
      minutes: [0],
      seconds: [0]
    ]

    schedule =
      @timestamp
      |> Cocktail.schedule()
      |> Cocktail.Schedule.add_recurrence_rule(:daily, options)

    {:ok, schedule: schedule}
  end

  describe "current" do
    test "returns current occurrence when passed identical timestamp", %{schedule: schedule} do
      exact_match = @timestamp
      one_second_after = Map.put(@timestamp, :second, 1)

      assert exact_match == Schedule.current(schedule, exact_match)
      assert one_second_after != Schedule.current(schedule, one_second_after)

      assert Schedule.current(schedule, exact_match) == ~U[2020-01-01 12:00:00Z]
      assert Schedule.current(schedule, one_second_after) == ~U[2020-01-02 12:00:00Z]
    end
  end
end
