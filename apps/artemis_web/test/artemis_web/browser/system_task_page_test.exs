defmodule ArtemisWeb.SystemTaskPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url system_task_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("System Tasks")
    end
  end

  describe "new / create" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "submitting an empty form shows an error" do
      click_link("New")
      submit_form("#system-task-form")

      assert visible?("can't be blank")
    end

    # test "successfully submits a new system task" do
    #   click_link("New")

    #   params = params_for(:system_task)

    #   fill_enhanced_select("#system-task-form", params.type)

    #   fill_inputs("#system-task-form", %{
    #     "system_task[extra_params]": Jason.encode!(params.extra_params),
    #   })

    #   submit_form("#system-task-form")

    #   assert visible?("Success")
    #   assert visible?("System Tasks")
    # end
  end
end
