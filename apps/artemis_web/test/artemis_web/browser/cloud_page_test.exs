defmodule ArtemisWeb.CloudPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url cloud_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      cloud = insert(:cloud)

      browser_sign_in()
      navigate_to(@url)

      {:ok, cloud: cloud}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Clouds")
    end

    test "search", %{cloud: cloud} do
      fill_inputs(".search-resource", %{
        query: cloud.slug
      })

      submit_search(".search-resource")

      assert visible?(cloud.slug)
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
      submit_form("#cloud-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#cloud-form", %{
        "cloud[name]": "Test Name",
        "cloud[slug]": "test-slug"
      })

      submit_form("#cloud-form")

      assert visible?("Test Name")
      assert visible?("test-slug")
    end
  end

  describe "show" do
    setup do
      cloud = insert(:cloud)

      Artemis.ListClouds.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, cloud: cloud}
    end

    test "record details", %{cloud: cloud} do
      click_link(cloud.name)

      assert visible?(cloud.name)
      assert visible?(cloud.slug)
    end
  end

  describe "edit / update" do
    setup do
      cloud = insert(:cloud)

      Artemis.ListClouds.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, cloud: cloud}
    end

    test "successfully updates record", %{cloud: cloud} do
      click_link(cloud.name)
      click_link("Edit")

      fill_inputs("#cloud-form", %{
        "cloud[name]": "Updated Name",
        "cloud[slug]": "updated-slug"
      })

      submit_form("#cloud-form")

      assert visible?("Updated Name")
      assert visible?("updated-slug")
    end
  end

  describe "delete" do
    setup do
      cloud = insert(:cloud)

      browser_sign_in()
      navigate_to(@url)

      {:ok, cloud: cloud}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{cloud: cloud} do
    #   click_link(cloud.name)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(cloud.name)
    # end
  end
end
