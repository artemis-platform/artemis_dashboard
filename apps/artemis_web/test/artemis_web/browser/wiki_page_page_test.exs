defmodule ArtemisWeb.WikiPagePageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url wiki_page_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      wiki_page = insert(:wiki_page)

      browser_sign_in()
      navigate_to(@url)

      {:ok, wiki_page: wiki_page}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Documentation")
    end

    test "search", %{wiki_page: wiki_page} do
      fill_inputs(".search-resource", %{
        query: wiki_page.title
      })

      submit_search(".search-resource")

      assert visible?(wiki_page.title)
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
      submit_form("#wiki-page-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#wiki-page-form", %{
        "wiki_page[title]": "Test Title"
      })

      submit_form("#wiki-page-form")

      assert visible?("Test Title")
    end
  end

  describe "show" do
    setup do
      wiki_page = insert(:wiki_page)

      browser_sign_in()
      navigate_to(@url)

      {:ok, wiki_page: wiki_page}
    end

    test "record details", %{wiki_page: wiki_page} do
      click_link(wiki_page.title)

      assert visible?(wiki_page.title)
    end
  end

  describe "edit / update" do
    setup do
      wiki_page = insert(:wiki_page)

      browser_sign_in()
      navigate_to(@url)

      {:ok, wiki_page: wiki_page}
    end

    test "successfully updates record", %{wiki_page: wiki_page} do
      click_link(wiki_page.title)
      click_link("Edit")

      fill_inputs("#wiki-page-form", %{
        "wiki_page[title]": "Updated Title"
      })

      submit_form("#wiki-page-form")

      assert visible?("Updated Title")
    end
  end

  describe "delete" do
    setup do
      wiki_page = insert(:wiki_page)

      browser_sign_in()
      navigate_to(@url)

      {:ok, wiki_page: wiki_page}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{wiki_page: wiki_page} do
    #   click_link(wiki_page.title)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(wiki_page.title)
    # end
  end
end
