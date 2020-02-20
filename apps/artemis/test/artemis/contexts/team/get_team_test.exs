defmodule Artemis.GetTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetTeam

  setup do
    team = insert(:team)
    insert(:user, teams: [team])

    {:ok, team: team}
  end

  describe "call" do
    test "returns nil team not found" do
      invalid_id = 50_000_000

      assert GetTeam.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds team by id", %{team: team} do
      assert GetTeam.call(team.id, Mock.system_user()).id == team.id
    end

    test "finds record by keyword list", %{team: team} do
      assert GetTeam.call([name: team.name], Mock.system_user()).id == team.id
    end
  end

  describe "call - options" do
    test "preload", %{team: team} do
      team = GetTeam.call(team.id, Mock.system_user())

      assert !is_list(team.users)
      assert team.users.__struct__ == Ecto.Association.NotLoaded

      values = [
        name: team.name
      ]

      options = [
        preload: [:users]
      ]

      team = GetTeam.call(values, Mock.system_user(), options)

      assert is_list(team.users)
    end
  end

  describe "call!" do
    test "raises an exception team not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetTeam.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds team by id", %{team: team} do
      assert GetTeam.call!(team.id, Mock.system_user()).id == team.id
    end
  end
end
