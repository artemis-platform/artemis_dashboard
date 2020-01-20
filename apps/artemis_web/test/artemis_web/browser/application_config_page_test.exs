defmodule ArtemisWeb.ApplicationConfigPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url application_config_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Application Configs")
    end
  end

  describe "show" do
    setup do
      browser_sign_in()
      navigate_to(@url)

      {:ok, []}
    end

    test "record details" do
      click_link("artemis")

      assert visible?("Application Config")
      assert visible?("artemis")
    end
  end
end
