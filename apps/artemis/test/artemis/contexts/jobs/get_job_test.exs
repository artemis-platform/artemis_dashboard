defmodule Artemis.GetJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetJob

  @moduletag :cloudant

  setup do
    job = cloudant_insert(:job)

    {:ok, job: job}
  end

  describe "call" do
    test "returns nil if record not found" do
      invalid_id = 50_000_000

      assert GetJob.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds record by id", %{job: job} do
      result = GetJob.call(job._id, Mock.system_user())

      assert result._id == job._id
    end
  end

  describe "call!" do
    test "raises an exception record not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        GetJob.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds record by id", %{job: job} do
      result = GetJob.call!(job._id, Mock.system_user())

      assert result._id == job._id
    end
  end
end
