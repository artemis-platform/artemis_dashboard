defmodule ArtemisWeb.DataCenterPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url data_center_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      data_center = insert(:data_center)

      browser_sign_in()
      navigate_to(@url)

      {:ok, data_center: data_center}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Data Centers")
    end

    test "search", %{data_center: data_center} do
      fill_inputs(".search-resource", %{
        query: data_center.name
      })

      submit_search(".search-resource")

      assert visible?(data_center.name)
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
      submit_form("#data-center-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#data-center-form", %{
        "data_center[name]": "Test Name",
        "data_center[slug]": "test-slug"
      })

      submit_form("#data-center-form")

      assert visible?("Test Name")
      assert visible?("test-slug")
    end
  end

  describe "show" do
    setup do
      data_center = insert(:data_center)

      Artemis.ListDataCenters.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, data_center: data_center}
    end

    test "record details", %{data_center: data_center} do
      click_link(data_center.name)

      assert visible?(data_center.name)
      assert visible?(data_center.slug)
    end
  end

  describe "edit / update" do
    setup do
      data_center = insert(:data_center)

      Artemis.ListDataCenters.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, data_center: data_center}
    end

    test "successfully updates record", %{data_center: data_center} do
      click_link(data_center.name)
      click_link("Edit")

      fill_inputs("#data-center-form", %{
        "data_center[name]": "Updated Name",
        "data_center[slug]": "updated-slug"
      })

      submit_form("#data-center-form")

      assert visible?("Updated Name")
      assert visible?("updated-slug")
    end
  end

  describe "delete" do
    setup do
      data_center = insert(:data_center)

      browser_sign_in()
      navigate_to(@url)

      {:ok, data_center: data_center}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{data_center: data_center} do
    #   click_link(data_center.name)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(data_center.name)
    # end
  end
end
