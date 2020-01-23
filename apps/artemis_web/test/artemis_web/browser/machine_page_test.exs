defmodule ArtemisWeb.MachinePageTest do
  use ArtemisWeb.ConnCase
  use ExUnit.Case
  use Hound.Helpers

  import Artemis.Factories
  import ArtemisWeb.BrowserHelpers
  import ArtemisWeb.Router.Helpers

  @moduletag :browser
  @url machine_url(ArtemisWeb.Endpoint, :index)

  hound_session()

  describe "authentication" do
    test "requires authentication" do
      navigate_to(@url)

      assert redirected_to_sign_in_page?()
    end
  end

  describe "index" do
    setup do
      machine = insert(:machine)

      browser_sign_in()
      navigate_to(@url)

      {:ok, machine: machine}
    end

    test "list of records" do
      assert page_title() == "Artemis"
      assert visible?("Machines")
    end

    test "search", %{machine: machine} do
      fill_inputs(".search-resource", %{
        query: machine.name
      })

      submit_search(".search-resource")

      assert visible?(machine.name)
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
      submit_form("#machine-form")

      assert visible?("can't be blank")
    end

    test "successfully creates a new record" do
      click_link("New")

      fill_inputs("#machine-form", %{
        "machine[name]": "Test Name",
        "machine[slug]": "test-slug"
      })

      submit_form("#machine-form")

      assert visible?("Test Name")
      assert visible?("test-slug")
    end
  end

  describe "show" do
    setup do
      machine = insert(:machine)

      Artemis.ListMachines.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, machine: machine}
    end

    test "record details", %{machine: machine} do
      click_link(machine.name)

      assert visible?(machine.name)
      assert visible?(machine.slug)
    end
  end

  describe "edit / update" do
    setup do
      machine = insert(:machine)

      Artemis.ListMachines.reset_cache()

      browser_sign_in()
      navigate_to(@url)

      {:ok, machine: machine}
    end

    test "successfully updates record", %{machine: machine} do
      click_link(machine.name)
      click_link("Edit")

      fill_inputs("#machine-form", %{
        "machine[name]": "Updated Name",
        "machine[slug]": "updated-slug"
      })

      submit_form("#machine-form")

      assert visible?("Updated Name")
      assert visible?("updated-slug")
    end
  end

  describe "delete" do
    setup do
      machine = insert(:machine)

      browser_sign_in()
      navigate_to(@url)

      {:ok, machine: machine}
    end

    @tag :uses_browser_alert_box
    # test "deletes record and redirects to index", %{machine: machine} do
    #   click_link(machine.name)
    #   click_button("Delete")
    #   accept_dialog()

    #   assert current_url() == @url
    #   assert not visible?(machine.name)
    # end
  end
end
