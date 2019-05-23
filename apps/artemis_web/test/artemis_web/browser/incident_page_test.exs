defmodule ArtemisWeb.IncidentPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url incident_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      incident = insert(:incident)

      browser_sign_in()
      navigate_to(@url)

      {:ok, incident: incident}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Incidents")
    end

    test "search", %{incident: incident} do
      fill_inputs(".search-resource", %{
        query: incident.source_uid
      })

      submit_search(".search-resource")

      assert visible?(incident.source_uid)
    end
  end

  describe "show" do
    setup do
      incident = insert(:incident)

      browser_sign_in()
      navigate_to(@url)

      {:ok, incident: incident}
    end

    test "record details", %{incident: incident} do
      click_link(incident.source_uid)

      assert visible?(incident.severity)
      assert visible?(incident.source)
      assert visible?(incident.source_uid)
      assert visible?(incident.status)
      assert visible?(incident.title)
    end
  end

  describe "delete" do
    setup do
      incident = insert(:incident)

      browser_sign_in()
      navigate_to(@url)

      {:ok, incident: incident}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{incident: incident} do
    #   click_link(incident.source_uid)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(incident.source_uid)
    # end
  end
end
