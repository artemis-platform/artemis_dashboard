defmodule Artemis.UpdateUserTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateUserTeam

  @preload [:created_by, :team, :user]

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:user_team)

      assert_raise Artemis.Context.Error, fn ->
        UpdateUserTeam.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      user_team = insert(:user_team)
      params = %{}

      updated = UpdateUserTeam.call!(user_team, params, Mock.system_user())

      assert updated.type == user_team.type
    end

    test "updates a record when passed valid params" do
      user_team = insert(:user_team, type: "member")
      params = params_for(:user_team, type: "admin")

      updated = UpdateUserTeam.call!(user_team, params, Mock.system_user())

      assert updated.type == params.type
    end

    test "updates a record when passed an id and valid params" do
      user_team = insert(:user_team, type: "member")
      params = params_for(:user_team, type: "admin")

      updated = UpdateUserTeam.call!(user_team.id, params, Mock.system_user())

      assert updated.type == params.type
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:user_team)

      {:error, _} = UpdateUserTeam.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      user_team = insert(:user_team)
      params = %{}

      {:ok, updated} = UpdateUserTeam.call(user_team, params, Mock.system_user())

      assert updated.type == user_team.type
    end

    test "updates a record value when passed valid params" do
      user_team = insert(:user_team, type: "member")
      params = params_for(:user_team, type: "admin")

      {:ok, updated} = UpdateUserTeam.call(user_team, params, Mock.system_user())

      assert updated.type == params.type
    end

    test "updates a record when passed an id and valid params" do
      user_team = insert(:user_team, type: "member")
      params = params_for(:user_team, type: "admin")

      {:ok, updated} = UpdateUserTeam.call(user_team.id, params, Mock.system_user())

      assert updated.type == params.type
    end

    test "updates record associations when passed valid params" do
      user_team = insert(:user_team)

      updated_user = insert(:user)
      updated_created_by = insert(:user)
      updated_team = insert(:team)

      refute Repo.preload(user_team, @preload).created_by.id == updated_created_by.id
      refute Repo.preload(user_team, @preload).team.id == updated_team.id
      refute Repo.preload(user_team, @preload).user.id == updated_user.id

      options = [
        created_by_id: updated_created_by.id,
        team_id: updated_team.id,
        user_id: updated_user.id
      ]

      params = params_for(:user_team, options)

      {:ok, updated} = UpdateUserTeam.call(user_team, params, Mock.system_user())

      updated = Repo.preload(updated, @preload, force: true)

      assert updated.team.id == updated_team.id
      assert updated.user.id == updated_user.id
      assert updated.created_by.id == updated_created_by.id
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      user_team = insert(:user_team, type: "member")
      params = params_for(:user_team, type: "admin")

      {:ok, updated} = UpdateUserTeam.call(user_team, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user-team:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
