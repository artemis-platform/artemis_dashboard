defmodule Artemis.Drivers.PagerDuty.SynchronizeIncidentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Drivers.PagerDuty.SynchronizeIncidents

  describe "calculate_since_date" do
    test "returns a default date when no records exist" do
      team_id = "TEST"

      result = SynchronizeIncidents.calculate_since_date(team_id, Mock.system_user())

      assert result.__struct__ == DateTime
    end

    test "returns the latest resolved incident if exists" do
      team_id = "TEST"

      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-03-10"))
      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-04-10"))

      result = SynchronizeIncidents.calculate_since_date(team_id, Mock.system_user())

      # Shifted one second forward to exclude record in next sync

      assert result == Timex.shift(create_date("2020-04-10"), seconds: 1)
    end

    test "restricts results to team_id" do
      team_id = "TEST"
      other_id = "OTHER"

      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-03-10"))
      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-04-10"))
      insert(:incident, status: "resolved", team_id: other_id, triggered_at: create_date("2020-05-10"))

      result = SynchronizeIncidents.calculate_since_date(team_id, Mock.system_user())

      # Shifted one second forward to exclude record in next sync

      assert result == Timex.shift(create_date("2020-04-10"), seconds: 1)
    end

    test "returns the earliest non-resolved incident if exists" do
      team_id = "TEST"

      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-03-10"))
      insert(:incident, status: "resolved", team_id: team_id, triggered_at: create_date("2020-04-10"))

      insert(:incident, status: "acknowledged", team_id: team_id, triggered_at: create_date("2020-01-10"))
      insert(:incident, status: "acknowledged", team_id: team_id, triggered_at: create_date("2020-02-10"))

      result = SynchronizeIncidents.calculate_since_date(team_id, Mock.system_user())

      # Shifted one second backward to include record in next sync

      assert result == Timex.shift(create_date("2020-01-10"), seconds: -1)
    end
  end

  # Helpers

  def create_date(date) do
    Timex.parse!("#{date}T00:00:00Z", "{ISO:Extended}")
  end
end
