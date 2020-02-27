defmodule Artemis.DeleteTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Team
  alias Artemis.DeleteTeam

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteTeam.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:team)

      %Team{} = DeleteTeam.call!(record, Mock.system_user())

      assert Repo.get(Team, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:team)

      %Team{} = DeleteTeam.call!(record.id, Mock.system_user())

      assert Repo.get(Team, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteTeam.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:team)

      {:ok, _} = DeleteTeam.call(record, Mock.system_user())

      assert Repo.get(Team, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:team)

      {:ok, _} = DeleteTeam.call(record.id, Mock.system_user())

      assert Repo.get(Team, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, team} = DeleteTeam.call(insert(:team), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "team:deleted",
        payload: %{
          data: ^team
        }
      }
    end
  end
end
