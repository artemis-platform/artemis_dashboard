defmodule Artemis.ListJobsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListJobs
  alias Artemis.Job

  @moduletag :cloudant

  setup do
    cloudant_delete_all(Job)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no jobs exist" do
      assert ListJobs.call(Mock.system_user()).entries == []
    end

    @tag :cloudant_exclusive_feature
    test "returns existing job" do
      job = cloudant_insert(:job)

      result = ListJobs.call(Mock.system_user())

      assert length(result.entries) == 1
      assert hd(result.entries)._id == job._id
    end

    @tag :cloudant_exclusive_feature
    test "returns a list of jobs" do
      count = 3
      cloudant_insert_list(count, :job)

      jobs = ListJobs.call(Mock.system_user()).entries

      assert length(jobs) == count
    end
  end

  describe "call - params" do
    setup do
      job = cloudant_insert(:job)

      {:ok, job: job}
    end

    @tag :cloudant_exclusive_feature
    test "query - search" do
      cloudant_insert(:job, name: "Four Six", status: "four-six")
      cloudant_insert(:job, name: "Four Two", status: "four-two")
      cloudant_insert(:job, name: "Five Six", status: "five-six")

      user = Mock.system_user()
      jobs = ListJobs.call(user).entries

      assert length(jobs) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "name:Six"
      }

      jobs = ListJobs.call(params, user).entries

      assert length(jobs) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "status:four*"
      }

      jobs = ListJobs.call(params, user).entries

      assert length(jobs) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "status:our*"
      }

      jobs = ListJobs.call(params, user).entries

      assert length(jobs) == 0
    end
  end
end
