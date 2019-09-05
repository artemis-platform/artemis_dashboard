defmodule ArtemisWeb.HttpRequestLogPageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import ArtemisLog.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url http_request_log_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      http_request_log = insert(:http_request_log)

      browser_sign_in()
      navigate_to(@url)

      {:ok, http_request_log: http_request_log}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Event Logs")
    end

    test "search", %{http_request_log: http_request_log} do
      fill_inputs(".search-resource", %{
        query: http_request_log.user_name
      })

      submit_search(".search-resource")

      assert visible?(http_request_log.user_name)
    end
  end

  describe "show" do
    setup do
      http_request_log = insert(:http_request_log)
      url = http_request_log_url(ArtemisWeb.Endpoint, :show, http_request_log)

      browser_sign_in()
      navigate_to(url)

      {:ok, http_request_log: http_request_log}
    end

    test "record details", %{http_request_log: http_request_log} do
      assert visible?(http_request_log.session_id)
      assert visible?(http_request_log.user_id)
      assert visible?(http_request_log.user_name)
    end
  end
end
