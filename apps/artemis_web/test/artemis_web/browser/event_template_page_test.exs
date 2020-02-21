defmodule ArtemisWeb.EventTemplatePageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url event_template_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      event_template = insert(:event_template)

      browser_sign_in()
      navigate_to(@url)

      {:ok, event_template: event_template}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Event Templates")
    end

    test "search", %{event_template: event_template} do
      fill_inputs(".search-resource", %{
        query: event_template.title
      })

      submit_search(".search-resource")

      assert visible?(event_template.title)
    end
  end

  describe "new / create" do
    setup do
      team = insert(:team)

      browser_sign_in()
      navigate_to(@url)

      {:ok, team: team}
    end

    test "submitting an empty form shows an error" do
      click_link("New")
      submit_form("#event-template-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record", %{team: team} do
      click_link("New")

      fill_inputs("#event-template-form", %{
        "event_template[title]": "Test Title"
      })

      fill_select("#event-template-form select[name=event_template[team_id]]", team.id)

      submit_form("#event-template-form")

      assert visible?("Test Title")
    end
  end

  describe "show" do
    setup do
      event_template = insert(:event_template)

      Artemis.ListEventTemplates.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, event_template: event_template}
    end

    test "record details", %{event_template: event_template} do
      click_link(event_template.title)

      assert visible?(event_template.title)
    end
  end

  describe "edit / update" do
    setup do
      event_template = insert(:event_template)

      Artemis.ListEventTemplates.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, event_template: event_template}
    end

    test "successfully updates record", %{event_template: event_template} do
      click_link(event_template.title)
      click_link("Edit")

      fill_inputs("#event-template-form", %{
        "event_template[title]": "Updated Title"
      })

      submit_form("#event-template-form")

      assert visible?("Updated Title")
    end
  end

  describe "delete" do
    setup do
      event_template = insert(:event_template)

      browser_sign_in()
      navigate_to(@url)

      {:ok, event_template: event_template}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{event_template: event_template} do
    #   click_link(event_template.title)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(event_template.title)
    # end
  end
end
