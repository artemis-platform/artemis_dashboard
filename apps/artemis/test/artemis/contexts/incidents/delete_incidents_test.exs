defmodule Artemis.DeleteIncidentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.Incident
  alias Artemis.DeleteIncident

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000

      assert_raise Artemis.Context.Error, fn () ->
        DeleteIncident.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:incident)

      %Incident{} = DeleteIncident.call!(record, Mock.system_user())

      assert Repo.get(Incident, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:incident)

      %Incident{} = DeleteIncident.call!(record.id, Mock.system_user())

      assert Repo.get(Incident, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50000000

      {:error, _} = DeleteIncident.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:incident)

      {:ok, _} = DeleteIncident.call(record, Mock.system_user())

      assert Repo.get(Incident, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:incident)

      {:ok, _} = DeleteIncident.call(record.id, Mock.system_user())

      assert Repo.get(Incident, record.id) == nil
    end

    test "deletes associated many to many associations" do
      record = insert(:incident)
      comments = insert_list(3, :comment, incidents: [record])
      _other = insert_list(2, :comment)

      total_before = Comment
        |> Repo.all()
        |> length()

      {:ok, _} = DeleteIncident.call(record.id, Mock.system_user())

      assert Repo.get(Incident, record.id) == nil

      total_after = Comment
        |> Repo.all()
        |> length()

      assert total_after == total_before - 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, incident} = DeleteIncident.call(insert(:incident), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "incident:deleted",
        payload: %{
          data: ^incident
        }
      }
    end
  end
end
