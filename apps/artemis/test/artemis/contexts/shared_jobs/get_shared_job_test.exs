defmodule Artemis.GetSharedJobTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetSharedJob

  @moduletag :cloudant

  setup do
    shared_job = cloudant_insert(:shared_job)

    {:ok, shared_job: shared_job}
  end

  describe "call" do
    test "returns nil if record not found" do
      invalid_id = 50_000_000

      assert GetSharedJob.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds record by id", %{shared_job: shared_job} do
      result = GetSharedJob.call(shared_job._id, Mock.system_user())

      assert result._id == shared_job._id
    end
  end

  describe "call!" do
    test "raises an exception record not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        GetSharedJob.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds record by id", %{shared_job: shared_job} do
      result = GetSharedJob.call!(shared_job._id, Mock.system_user())

      assert result._id == shared_job._id
    end
  end
end
