defmodule Artemis.CreateSharedJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateSharedJob
  alias Artemis.SharedJob

  @moduletag :cloudant

  setup do
    cloudant_delete_all(SharedJob)

    {:ok, []}
  end

  describe "call!" do
    test "creates an empty document when params are empty" do
      params = %{}

      shared_job = CreateSharedJob.call!(params, Mock.system_user())

      assert shared_job._id != nil
      assert shared_job._rev != nil
      assert shared_job.name == nil
    end

    test "creates a shared job when passed valid params" do
      params = params_for(:shared_job)

      shared_job = CreateSharedJob.call!(params, Mock.system_user())

      assert shared_job.name == params.name
    end
  end

  describe "call" do
    test "creates an empty document when params are empty" do
      params = %{}

      {:ok, shared_job} = CreateSharedJob.call(params, Mock.system_user())

      assert shared_job._id != nil
      assert shared_job._rev != nil
      assert shared_job.name == nil
    end

    test "creates a shared job when passed valid params" do
      params = params_for(:shared_job)

      {:ok, shared_job} = CreateSharedJob.call(params, Mock.system_user())

      assert shared_job.name == params.name
    end

    test "if passed, the `raw_data` attribute trumps other values" do
      created_name = "New Name"

      params = %{
        name: "Ignored Name",
        raw_data: %{
          name: created_name
        },
        status: "Ignored Status Update"
      }

      {:ok, shared_job} = CreateSharedJob.call(params, Mock.system_user())

      assert shared_job.name == created_name
      assert shared_job.status == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, shared_job} = CreateSharedJob.call(params_for(:shared_job), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "shared-job:created",
        payload: %{
          data: ^shared_job
        }
      }
    end
  end
end
