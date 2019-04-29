defmodule ArtemisWeb.WikiPageTagPageTest do
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
      tag = insert(:tag, wiki_pages: [wiki_page])

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, tag: tag, wiki_page: wiki_page}
    end

    test "list of records", %{tag: tag} do
      assert page_title() == "Artemis"
      assert visible?("Documentation")
      assert visible?("Edit Tags")
      assert visible?(tag.name)
    end
  end

  describe "edit / update" do
    setup do
      wiki_page = insert(:wiki_page)
      tag = insert(:tag, wiki_pages: [wiki_page])

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, tag: tag, wiki_page: wiki_page}
    end

    test "successfully updates records" do
      click_link("Edit Tags")

      fill_enhanced_select("#tag-form", ["First Tag Name", "Second Tag Name"])

      submit_form("#tag-form")

      assert visible?("First Tag Name")
      assert visible?("Second Tag Name")
    end
  end
end
