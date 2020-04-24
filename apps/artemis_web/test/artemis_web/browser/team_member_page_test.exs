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

    test "lists team members" do
      assert page_title() == "Artemis"
      assert visible?("Team Members")
    end
  end

  describe "new / create" do
    setup do
      team = insert(:team)
      user = insert(:user)
      other_user = insert(:user)
      user_team = insert(:user_team, team: team, user: user)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, other_user: other_user, team: team, user: user, user_team: user_team}
    end

    test "submitting an empty form shows an error" do
      click_link("New Team Member")
      submit_form("#team-member-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record", %{other_user: other_user, user_team: user_team} do
      click_link("New Team Member")

      fill_select("#team-member-form select#user_team_type", user_team.type)
      fill_select("#team-member-form select#user_team_user_id", other_user.id)

      submit_form("#team-member-form")

      assert visible?(user_team.type)
      assert visible?(other_user.name)
    end
  end

  describe "show" do
    setup do
      user_team = insert(:user_team)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, user_team: user_team}
    end

    test "record details", %{user_team: user_team} do
      click_link(user_team.user.name)

      assert visible?(user_team.type)
    end
  end

  describe "edit / update" do
    setup do
      team = insert(:team)
      user = insert(:user)
      type = List.first(Artemis.UserTeam.allowed_types())
      user_team = insert(:user_team, team: team, type: type, user: user)
      url = get_url(user_team.team)

      browser_sign_in()
      navigate_to(url)

      {:ok, team: team, user: user, user_team: user_team}
    end

    test "successfully updates record", %{user_team: user_team} do
      click_link(user_team.user.name)
      click_link("Edit")

      new_type = List.last(Artemis.UserTeam.allowed_types())

      fill_select("#team-member-form select#user_team_type", new_type)

      submit_form("#team-member-form")

      assert visible?(new_type)
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
    team_url(ArtemisWeb.Endpoint, :show, team)
  end
end
