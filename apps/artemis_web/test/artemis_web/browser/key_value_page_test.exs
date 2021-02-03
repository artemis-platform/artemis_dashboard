defmodule ArtemisWeb.KeyValuePageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url key_value_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      key_value = insert(:key_value)

      browser_sign_in()
      navigate_to(@url)

      {:ok, key_value: key_value}
    end

    test "list of records" do
      assert page_title() == "Atlas"
      assert visible?("Key Values")
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
      submit_form("#key-value-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#key-value-form", %{
        "key_value[key]": "Test Key",
        "key_value[value]": "test-value"
      })

      submit_form("#key-value-form")

      assert visible?("Test Key")
      assert visible?("test-value")
    end
  end

  describe "show" do
    setup do
      key_value = insert(:key_value)

      Artemis.ListKeyValues.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, key_value: key_value}
    end

    test "record details", %{key_value: key_value} do
      click_link(key_value.key)

      assert visible?(key_value.key)
      assert visible?(key_value.value)
    end
  end

  describe "edit / update" do
    setup do
      key_value = insert(:key_value)

      Artemis.ListKeyValues.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, key_value: key_value}
    end

    test "successfully updates record", %{key_value: key_value} do
      click_link(key_value.key)
      click_link("Edit")

      fill_inputs("#key-value-form", %{
        "key_value[key]": "Updated Key",
        "key_value[value]": "updated-value"
      })

      submit_form("#key-value-form")

      assert visible?("Updated Key")
      assert visible?("updated-value")
    end
  end

  describe "delete" do
    setup do
      key_value = insert(:key_value)

      browser_sign_in()
      navigate_to(@url)

      {:ok, key_value: key_value}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{key_value: key_value} do
    #   click_link(key_value.key)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(key_value.key)
    # end
  end
end
