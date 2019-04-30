defmodule ArtemisWeb.TagPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url tag_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      tag = insert(:tag)

      browser_sign_in()
      navigate_to(@url)

      {:ok, tag: tag}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Tags")
    end

    test "search", %{tag: tag} do
      fill_inputs(".search-resource", %{
        query: tag.slug
      })

      submit_search(".search-resource")

      assert visible?(tag.slug)
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
      submit_form("#tag-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#tag-form", %{
        "tag[name]": "Test Name",
        "tag[slug]": "test-slug",
        "tag[type]": "test-type"
      })

      submit_form("#tag-form")

      assert visible?("Test Name")
      assert visible?("test-slug")
      assert visible?("test-type")
    end
  end

  describe "show" do
    setup do
      tag = insert(:tag)

      browser_sign_in()
      navigate_to(@url)

      {:ok, tag: tag}
    end

    test "record details", %{tag: tag} do
      click_link(tag.slug)

      assert visible?(tag.name)
      assert visible?(tag.slug)
    end
  end

  describe "edit / update" do
    setup do
      tag = insert(:tag)

      browser_sign_in()
      navigate_to(@url)

      {:ok, tag: tag}
    end

    test "successfully updates record", %{tag: tag} do
      click_link(tag.slug)
      click_link("Edit")

      fill_inputs("#tag-form", %{
        "tag[name]": "Updated Name",
        "tag[slug]": "updated-slug"
      })

      submit_form("#tag-form")

      assert visible?("Updated Name")
      assert visible?("updated-slug")
    end
  end

  describe "delete" do
    setup do
      tag = insert(:tag)

      browser_sign_in()
      navigate_to(@url)

      {:ok, tag: tag}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{tag: tag} do
    #   click_link(tag.slug)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(tag.slug)
    # end
  end
end
