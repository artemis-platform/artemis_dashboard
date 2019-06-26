defmodule Artemis.DeleteSharedJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.DeleteSharedJob
  alias Artemis.GetSharedJob

  @moduletag :cloudant

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteSharedJob.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = cloudant_insert(:shared_job)

      %{} = DeleteSharedJob.call!(record, Mock.system_user())

      assert GetSharedJob.call(record._id, Mock.system_user()) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = cloudant_insert(:shared_job)

      %{} = DeleteSharedJob.call!(record._id, Mock.system_user())

      assert GetSharedJob.call(record._id, Mock.system_user()) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteSharedJob.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = cloudant_insert(:shared_job)

      {:ok, _} = DeleteSharedJob.call(record, Mock.system_user())

      assert GetSharedJob.call(record._id, Mock.system_user()) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = cloudant_insert(:shared_job)

      {:ok, _} = DeleteSharedJob.call(record._id, Mock.system_user())

      assert GetSharedJob.call(record._id, Mock.system_user()) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, shared_job} = DeleteSharedJob.call(cloudant_insert(:shared_job), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "shared-jobs:deleted",
        payload: %{
          data: ^shared_job
        }
      }
    end
  end
end
