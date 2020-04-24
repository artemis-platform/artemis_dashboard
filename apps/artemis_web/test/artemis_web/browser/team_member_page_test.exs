defmodule ArtemisWeb.TeamMemberPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      team = insert(:team)
      url = get_url(team)

      navigate_to(url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Team Users")
    end

    test "search", %{user_team: user_team} do
      fill_inputs(".search-resource", %{
        query: user_team.title
      })

      submit_search(".search-resource")

      assert visible?(user_team.title)
    end
  end

  describe "new / create" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    test "submitting an empty form shows an error" do
      click_link("New")
      submit_form("#team-user-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record", %{user_team: user_team} do
      click_link("New")

      fill_inputs("#team-user-form", %{
        "user_team[title]": "Test Title"
      })

      fill_select("#team-user-form select[name=user_team[user_team_id]]", user_team.id)

      submit_form("#team-user-form")

      assert visible?("Test Title")
    end
  end

  describe "show" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      Artemis.ListUserTeams.reset_cache()

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    test "record details", %{user_team: user_team} do
      click_link(user_team.title)

      assert visible?(user_team.title)
    end
  end

  describe "edit / update" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      Artemis.ListUserTeams.reset_cache()

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    test "successfully updates record", %{user_team: user_team} do
      click_link(user_team.title)
      click_link("Edit")

      fill_inputs("#team-user-form", %{
        "user_team[title]": "Updated Title"
      })

      submit_form("#team-user-form")

      assert visible?("Updated Title")
    end
  end

  describe "delete" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{user_team: user_team} do
    #   click_link(user_team.title)
    #   click_button("Delete")
    #   accept_dialog()
    #
    #   assert current_url() == get_url(user_team.team)
    #   assert not visible?(user_team.title)
    # end
  end

  # Helpers

  defp get_url(team) do
    user_team = insert(:user_team, team: team)

    team_member_url(ArtemisWeb.Endpoint, :index, team)
  end
end
