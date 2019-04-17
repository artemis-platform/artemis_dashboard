defmodule ArtemisWeb.WikiPageCommentPageTest do
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
      comment = insert(:comment, wiki_pages: [wiki_page])

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, comment: comment, wiki_page: wiki_page}
    end

    test "list of records", %{comment: comment} do
      assert page_title() == "Artemis"
      assert visible?("Documentation")
      assert visible?("Comments")
      assert visible?(comment.title)
    end
  end

  describe "new / create" do
    setup do
      wiki_page = insert(:wiki_page)

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, wiki_page: wiki_page}
    end

    test "submitting an empty form shows an error" do
      submit_form("#comment-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      fill_inputs("#comment-form", %{
        "comment[body]": "Test Body",
        "comment[title]": "Test Title"
      })

      submit_form("#comment-form")

      assert visible?("Test Title")
      assert visible?("Test Body")
    end
  end

  describe "edit / update" do
    setup do
      wiki_page = insert(:wiki_page)
      comment = insert(:comment, wiki_pages: [wiki_page])

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, comment: comment, wiki_page: wiki_page}
    end

    test "submitting an empty form shows an error" do
      click_link("Edit Comment")

      fill_inputs("#comment-form", %{
        "comment[title]": ""
      })

      submit_form("#comment-form")

      assert visible?("can't be blank")
    end

    test "successfully updates record" do
      click_link("Edit Comment")

      fill_inputs("#comment-form", %{
        "comment[title]": "Updated Comment Title"
      })

      submit_form("#comment-form")

      assert visible?("Updated Comment Title")
    end
  end

  describe "delete" do
    setup do
      wiki_page = insert(:wiki_page)
      comment = insert(:comment, wiki_pages: [wiki_page])

      browser_sign_in()
      navigate_to(@url)

      click_link(wiki_page.title)

      {:ok, comment: comment, wiki_page: wiki_page}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{comment: comment, wiki_page: wiki_page} do
    #   click_link("Delete Comment")
    #   accept_dialog()

    #   assert current_url() == wiki_page_url(ArtemisWeb.Endpoint, :show, wiki_page)
    #   assert not visible?(comment.title)
    # end
  end
end
