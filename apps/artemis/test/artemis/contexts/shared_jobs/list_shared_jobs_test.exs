defmodule Artemis.ListSharedJobsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListSharedJobs
  alias Artemis.SharedJob

  @moduletag :cloudant

  setup do
    cloudant_delete_all(SharedJob)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no shared jobs exist" do
      assert ListSharedJobs.call(Mock.system_user()) == []
    end

    @tag :cloudant_exclusive_feature
    test "returns existing shared job" do
      shared_job = cloudant_insert(:shared_job)

      result = ListSharedJobs.call(Mock.system_user())

      assert length(result) == 1
      assert hd(result)._id == shared_job._id
    end

    @tag :cloudant_exclusive_feature
    test "returns a list of shared jobs" do
      count = 3
      cloudant_insert_list(count, :shared_job)

      shared_jobs = ListSharedJobs.call(Mock.system_user())

      assert length(shared_jobs) == count
    end
  end

  describe "call - params" do
    setup do
      shared_job = cloudant_insert(:shared_job)

      {:ok, shared_job: shared_job}
    end

    @tag :cloudant_exclusive_feature
    test "query - search" do
      cloudant_insert(:shared_job, name: "Four Six", status: "four-six")
      cloudant_insert(:shared_job, name: "Four Two", status: "four-two")
      cloudant_insert(:shared_job, name: "Five Six", status: "five-six")

      user = Mock.system_user()
      shared_jobs = ListSharedJobs.call(user)

      assert length(shared_jobs) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "name:Six"
      }

      shared_jobs = ListSharedJobs.call(params, user)

      assert length(shared_jobs) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "status:four*"
      }

      shared_jobs = ListSharedJobs.call(params, user)

      assert length(shared_jobs) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "status:our*"
      }

      shared_jobs = ListSharedJobs.call(params, user)

      assert length(shared_jobs) == 0
    end
  end
end
