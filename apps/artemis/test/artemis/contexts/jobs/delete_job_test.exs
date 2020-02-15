defmodule Artemis.DeleteJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
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

    test "deletes associated comments" do
      record = cloudant_insert(:job)
      comments = insert_list(3, :comment, resource_type: "Job", resource_id: record._id)
      _other = insert_list(2, :comment)

      total_before =
        Comment
        |> Repo.all()
        |> length()

      {:ok, _} = DeleteJob.call(record._id, Mock.system_user())

      assert GetJob.call(record._id, Mock.system_user()) == nil

      total_after =
        Comment
        |> Repo.all()
        |> length()

      assert total_after == total_before - 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, job} = DeleteJob.call(cloudant_insert(:job), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "job:deleted",
        payload: %{
          data: ^job
        }
      }
    end
  end
end
