defmodule Artemis.CreateUserTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateUserTeam

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Postgrex.Error, fn ->
        CreateUserTeam.call!(%{}, Mock.system_user())
      end
    end

    test "creates a user_team when passed valid params" do
      user = insert(:user)
      team = insert(:team)

      params = params_for(:user_team, created_by: user, team: team, user: user)

      user_team = CreateUserTeam.call!(params, Mock.system_user())

      assert user_team.team_id == params.team_id
    end
  end

  describe "call" do
    test "raises an error when params are empty" do
      assert_raise Postgrex.Error, fn ->
        CreateUserTeam.call!(%{}, Mock.system_user())
      end
    end

    test "creates a user_team when passed valid params" do
      user = insert(:user)
      team = insert(:team)

      params = params_for(:user_team, created_by: user, team: team, user: user)

      {:ok, user_team} = CreateUserTeam.call(params, Mock.system_user())

      assert user_team.team_id == params.team_id
      assert user_team.user_id == params.user_id
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      user = insert(:user)
      team = insert(:team)

      params = params_for(:user_team, created_by: user, team: team, user: user)

      {:ok, user_team} = CreateUserTeam.call(params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user-team:created",
        payload: %{
          data: ^user_team
        }
      }
    end
  end
end
