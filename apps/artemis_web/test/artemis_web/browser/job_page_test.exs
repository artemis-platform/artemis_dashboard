defmodule ArtemisWeb.JobPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  alias Artemis.Job

  @moduletag :browser
  @url job_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  setup_all do
    Artemis.DataCase.cloudant_delete_all(Job)

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
      job = cloudant_insert(:job)

      browser_sign_in()
      navigate_to(@url)

      {:ok, job: job}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Jobs")
    end

    # @tag :cloudant_exclusive_feature
    # test "search", %{job: job} do
    #   fill_inputs(".search-resource", %{
    #     query: job.name
    #   })

    #   submit_search(".search-resource")

    #   assert visible?(job.name)
    # end
  end

  describe "new / create" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "submitting an invalid form shows an error" do
      click_link("New")

      fill_inputs("#job-form", %{
        "job[raw_data]": "{"
      })

      submit_form("#job-form")

      assert visible?("is invalid")
    end

    test "successfully creates a new record" do
      click_link("New")

      raw_data = %{
        name: "Test Name",
        status: "Completed"
      }

      fill_inputs("#job-form", %{
        "job[raw_data]": Jason.encode!(raw_data)
      })

      submit_form("#job-form")

      assert visible?("Test Name")
      assert visible?("Completed")
    end
  end

  describe "show" do
    setup do
      job = cloudant_insert(:job)

      browser_sign_in()
      navigate_to("#{@url}/#{job._id}")

      {:ok, job: job}
    end

    test "record details", %{job: job} do
      assert visible?(job.name)
      assert visible?(job.status)
    end
  end

  describe "edit / update" do
    setup do
      job = cloudant_insert(:job)

      browser_sign_in()
      navigate_to("#{@url}/#{job._id}")

      {:ok, job: job}
    end

    test "successfully updates record" do
      click_link("Edit")

      raw_data = %{
        name: "Updated Name",
        status: "Queued"
      }

      fill_inputs("#job-form", %{
        "job[raw_data]": Jason.encode!(raw_data)
      })

      submit_form("#job-form")

      assert visible?("Updated Name")
      assert visible?("Queued")
    end
  end

  describe "delete" do
    setup do
      job = cloudant_insert(:job)

      browser_sign_in()
      navigate_to("#{@url}/#{job._id}")

      {:ok, job: job}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{job: job} do
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(job._id)
    # end
  end
end
