defmodule ArtemisWeb.WikiRevisionPageTest do
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
      wiki_revision = insert(:wiki_revision, wiki_page: wiki_page)

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)
      click_link("View Revisions")

      {:ok, wiki_page: wiki_page, wiki_revision: wiki_revision}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Documentation")
    end

    test "search", %{wiki_revision: wiki_revision} do
      fill_inputs(".search-resource", %{
        query: wiki_revision.title
      })

      submit_search(".search-resource")

      assert visible?(wiki_revision.title)
    end
  end

  describe "show" do
    setup do
      wiki_page = insert(:wiki_page)
      wiki_revision = insert(:wiki_revision, wiki_page: wiki_page)

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)
      click_link("View Revisions")

      {:ok, wiki_page: wiki_page, wiki_revision: wiki_revision}
    end

    test "record details", %{wiki_revision: wiki_revision} do
      click_link(wiki_revision.title)

      assert visible?(wiki_revision.title)
      assert visible?("Notice")
    end
  end

  describe "delete" do
    setup do
      wiki_page = insert(:wiki_page)
      wiki_revision = insert(:wiki_revision, wiki_page: wiki_page)

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)
      click_link("View Revisions")

      {:ok, wiki_page: wiki_page, wiki_revision: wiki_revision}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{wiki_revision: wiki_revision} do
    #   click_link(wiki_revision.title)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(wiki_revision.title)
    # end
  end
end
