defmodule ArtemisWeb.HomePageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url home_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "when unauthenticated show log in link" do
      navigate_to(@url)

      assert visible?("Log In")
    end

    test "when authenticated do not show log in link" do
      browser_sign_in()
      navigate_to(@url)

      assert not visible?("Log In")
    end
  end

  describe "index" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "page content" do
      assert page_title() == "Artemis"
      assert visible?("Artemis Dashboard")
    end

    test "current user sidebar" do
      click({:css, ".open-sidebar-current-user"})

      assert visible?("Profile")
      assert visible?("View Profile")
      assert visible?("Log Out")
    end
  end
end
