defmodule Artemis.UpdateJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateJob

  @moduletag :cloudant

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = get_update_params()

      assert_raise Artemis.Context.Error, fn ->
        UpdateJob.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      job = cloudant_insert(:job)
      params = %{}

      updated = UpdateJob.call!(job, params, Mock.system_user())

      assert updated.name == job.name
    end

    test "updates a record when passed valid params" do
      job = cloudant_insert(:job)
      params = get_update_params()

      updated = UpdateJob.call!(job, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      job = cloudant_insert(:job)
      params = get_update_params()

      updated = UpdateJob.call!(job._id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = get_update_params()

      {:error, _} = UpdateJob.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      job = cloudant_insert(:job)
      params = %{}

      {:ok, updated} = UpdateJob.call(job, params, Mock.system_user())

      assert updated.name == job.name
    end

    test "updates a record when passed valid params" do
      job = cloudant_insert(:job)
      params = get_update_params()

      {:ok, updated} = UpdateJob.call(job, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      job = cloudant_insert(:job)
      params = get_update_params()

      {:ok, updated} = UpdateJob.call(job._id, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates only the passed attributes" do
      job = cloudant_insert(:job)
      updated_name = "Updated Name"
      params = %{name: updated_name}

      assert job.name != updated_name
      assert job.status != nil

      {:ok, updated} = UpdateJob.call(job, params, Mock.system_user())

      assert updated.name == params.name
      assert updated.status == job.status
    end

    test "if passed, the `raw_data` attribute trumps other values" do
      job = cloudant_insert(:job)
      updated_name = "Updated Name"

      params = %{
        name: "Ignored Name",
        raw_data: %{
          name: updated_name
        },
        status: "Ignored Status Update"
      }

      assert job.name != updated_name
      assert job.status != nil

      {:ok, updated} = UpdateJob.call(job, params, Mock.system_user())

      assert updated.name == params.raw_data.name
      assert updated.status == nil
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      job = cloudant_insert(:job)
      params = get_update_params()

      {:ok, updated} = UpdateJob.call(job, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "job:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end

  # Helpers

  defp get_update_params() do
    :job
    |> params_for()
    |> Map.delete(:_id)
    |> Map.delete(:_rev)
  end
end
