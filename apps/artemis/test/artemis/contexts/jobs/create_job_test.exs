defmodule Artemis.CreateJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateJob
  alias Artemis.Job

  @moduletag :cloudant

  setup do
    cloudant_delete_all(Job)

    {:ok, []}
  end

  describe "call!" do
    test "creates an empty document when params are empty" do
      params = %{}

      job = CreateJob.call!(params, Mock.system_user())

      assert job._id != nil
      assert job._rev != nil
      assert job.name == nil
    end

    test "creates a job when passed valid params" do
      params = params_for(:job)

      job = CreateJob.call!(params, Mock.system_user())

      assert job.name == params.name
    end
  end

  describe "call" do
    test "creates an empty document when params are empty" do
      params = %{}

      {:ok, job} = CreateJob.call(params, Mock.system_user())

      assert job._id != nil
      assert job._rev != nil
      assert job.name == nil
    end

    test "creates a job when passed valid params" do
      params = params_for(:job)

      {:ok, job} = CreateJob.call(params, Mock.system_user())

      assert job.name == params.name
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

      {:ok, job} = CreateJob.call(params, Mock.system_user())

      assert job.name == created_name
      assert job.status == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, job} = CreateJob.call(params_for(:job), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "job:created",
        payload: %{
          data: ^job
        }
      }
    end
  end
end
