defmodule ArtemisWeb.TeamPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url team_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      team = insert(:team)

      browser_sign_in()
      navigate_to(@url)

      {:ok, team: team}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Teams")
    end

    test "search", %{team: team} do
      fill_inputs(".search-resource", %{
        query: team.name
      })

      submit_search(".search-resource")

      assert visible?(team.name)
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
      submit_form("#team-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#team-form", %{
        "team[name]": "Test Name"
      })

      submit_form("#team-form")

      assert visible?("Test Name")
    end
  end

  describe "show" do
    setup do
      team = insert(:team)

      insert_list(3, :user_team, team: team)

      browser_sign_in()
      navigate_to(@url)

      {:ok, team: team}
    end

    test "record details and associations", %{team: team} do
      click_link(team.name)

      assert visible?(team.name)

      assert visible?("Permissions")
    end
  end

  describe "edit / update" do
    setup do
      team = insert(:team)

      browser_sign_in()
      navigate_to(@url)

      {:ok, team: team}
    end

    test "successfully updates record", %{team: team} do
      click_link(team.name)
      click_link("Edit")

      fill_inputs("#team-form", %{
        "team[name]": "Updated Name"
      })

      submit_form("#team-form")

      assert visible?("Updated Name")
    end
  end

  describe "delete" do
    setup do
      team = insert(:team)

      browser_sign_in()
      navigate_to(@url)

      {:ok, team: team}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{team: team} do
    #   click_link(team.name)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(team.name)
    # end
  end
end
