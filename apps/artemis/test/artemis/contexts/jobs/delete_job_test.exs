defmodule Artemis.DeleteJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.DeleteJob
  alias Artemis.GetJob

  @moduletag :cloudant

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteJob.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = cloudant_insert(:job)

      %{} = DeleteJob.call!(record, Mock.system_user())

      assert GetJob.call(record._id, Mock.system_user()) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = cloudant_insert(:job)

      %{} = DeleteJob.call!(record._id, Mock.system_user())

      assert GetJob.call(record._id, Mock.system_user()) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteJob.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = cloudant_insert(:job)

      {:ok, _} = DeleteJob.call(record, Mock.system_user())

      assert GetJob.call(record._id, Mock.system_user()) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = cloudant_insert(:job)

      {:ok, _} = DeleteJob.call(record._id, Mock.system_user())

      assert GetJob.call(record._id, Mock.system_user()) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, job} = DeleteJob.call(cloudant_insert(:job), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "jobs:deleted",
        payload: %{
          data: ^job
        }
      }
    end
  end
end
