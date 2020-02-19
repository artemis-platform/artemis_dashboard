defmodule Artemis.DeleteUserTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UserTeam
  alias Artemis.DeleteUserTeam

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteUserTeam.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:user_team)

      %UserTeam{} = DeleteUserTeam.call!(record, Mock.system_user())

      assert Repo.get(UserTeam, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:user_team)

      %UserTeam{} = DeleteUserTeam.call!(record.id, Mock.system_user())

      assert Repo.get(UserTeam, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteUserTeam.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:user_team)

      {:ok, _} = DeleteUserTeam.call(record, Mock.system_user())

      assert Repo.get(UserTeam, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:user_team)

      {:ok, _} = DeleteUserTeam.call(record.id, Mock.system_user())

      assert Repo.get(UserTeam, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, user_team} = DeleteUserTeam.call(insert(:user_team), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user-team:deleted",
        payload: %{
          data: ^user_team
        }
      }
    end
  end
end
