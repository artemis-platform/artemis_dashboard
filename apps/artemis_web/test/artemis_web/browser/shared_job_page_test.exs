defmodule ArtemisWeb.SharedJobPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  alias Artemis.SharedJob

  @moduletag :browser
  @url shared_job_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  setup_all do
    Artemis.DataCase.cloudant_delete_all(SharedJob)

    {:ok, []}
  end

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      shared_job = cloudant_insert(:shared_job)

      browser_sign_in()
      navigate_to(@url)

      {:ok, shared_job: shared_job}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Shared Jobs")
    end

    @tags :cloudant_exclusive_feature
    test "search", %{shared_job: shared_job} do
      fill_inputs(".search-resource", %{
        query: shared_job.name
      })

      submit_search(".search-resource")

      assert visible?(shared_job.name)
    end
  end

  describe "new / create" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "submitting an invalid form shows an error" do
      click_link("New")

      fill_inputs("#shared-job-form", %{
        "shared_job[raw_data]": "{"
      })

      submit_form("#shared-job-form")

      assert visible?("is invalid")
    end

    test "successfully creates a new record" do
      click_link("New")

      raw_data = %{
        name: "Test Name",
        status: "Completed"
      }

      fill_inputs("#shared-job-form", %{
        "shared_job[raw_data]": Jason.encode!(raw_data)
      })

      submit_form("#shared-job-form")

      assert visible?("Test Name")
      assert visible?("Completed")
    end
  end

  describe "show" do
    setup do
      shared_job = cloudant_insert(:shared_job)

      browser_sign_in()
      navigate_to("#{@url}/#{shared_job._id}")

      {:ok, shared_job: shared_job}
    end

    test "record details", %{shared_job: shared_job} do
      assert visible?(shared_job.name)
      assert visible?(shared_job.status)
    end
  end

  describe "edit / update" do
    setup do
      shared_job = cloudant_insert(:shared_job)

      browser_sign_in()
      navigate_to("#{@url}/#{shared_job._id}")

      {:ok, shared_job: shared_job}
    end

    test "successfully updates record", %{shared_job: shared_job} do
      click_link("Edit")

      raw_data = %{
        name: "Updated Name",
        status: "Pending"
      }

      fill_inputs("#shared-job-form", %{
        "shared_job[raw_data]": Jason.encode!(raw_data)
      })

      submit_form("#shared-job-form")

      assert visible?("Updated Name")
      assert visible?("Pending")
    end
  end

  describe "delete" do
    setup do
      shared_job = cloudant_insert(:shared_job)

      browser_sign_in()
      navigate_to("#{@url}/#{shared_job._id}")

      {:ok, shared_job: shared_job}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{shared_job: shared_job} do
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(shared_job._id)
    # end
  end
end
