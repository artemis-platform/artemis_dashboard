defmodule Artemis.DeleteAllIncidentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.DeleteAllIncidents
  alias Artemis.Incident

  describe "call!" do
    test "deletes all records" do
      insert_list(3, :incident)

      incident_count =
        Incident
        |> Repo.all()
        |> length()

      assert incident_count != 0

      deleted_count = DeleteAllIncidents.call!(Mock.system_user())

      incident_count =
        Incident
        |> Repo.all()
        |> length()

      assert incident_count == 0
      assert deleted_count == 3
    end
  end

  describe "call" do
    test "deletes all records" do
      insert_list(3, :incident)

      incident_count =
        Incident
        |> Repo.all()
        |> length()

      assert incident_count != 0

      {:ok, deleted_count} = DeleteAllIncidents.call(Mock.system_user())

      incident_count =
        Incident
        |> Repo.all()
        |> length()

      assert incident_count == 0
      assert deleted_count == 3
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, result} = DeleteAllIncidents.call(Mock.system_user())

      expected = %{records_deleted: result}

      assert_received %Phoenix.Socket.Broadcast{
        event: "incident:deleted:all",
        payload: %{
          data: ^expected
        }
      }
    end
  end
end
