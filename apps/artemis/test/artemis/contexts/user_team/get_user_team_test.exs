defmodule Artemis.GetUserTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetUserTeam

  setup do
    user_team = insert(:user_team)

    {:ok, user_team: user_team}
  end

  describe "call" do
    test "returns nil user_team not found" do
      invalid_id = 50_000_000

      assert GetUserTeam.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds user_team by id", %{user_team: user_team} do
      assert GetUserTeam.call(user_team.id, Mock.system_user()).id == user_team.id
    end

    test "finds record by keyword list", %{user_team: user_team} do
      assert GetUserTeam.call([team_id: user_team.team_id, user_id: user_team.user_id], Mock.system_user()).id ==
               user_team.id
    end
  end

  describe "call!" do
    test "raises an exception user_team not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetUserTeam.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds user_team by id", %{user_team: user_team} do
      assert GetUserTeam.call!(user_team.id, Mock.system_user()).id == user_team.id
    end
  end
end
