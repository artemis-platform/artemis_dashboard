defmodule ArtemisWeb.CustomersLive.ShowTest do
  use ArtemisWeb.ConnCase

  import Phoenix.LiveViewTest
  import Artemis.CustomersFixtures

  @create_attrs %{name: "some name", notes: "some notes"}
  @update_attrs %{name: "some updated name", notes: "some updated notes"}
  @invalid_attrs %{name: nil, notes: nil}

  setup :register_and_log_in_user

  defp create(%{scope: scope}) do
    customer = customer_fixture(scope)

    %{customer: customer}
  end

  describe "Show" do
    setup [:create]

    test "displays customer", %{conn: conn, customer: customer} do
      {:ok, _show_live, html} = live(conn, ~p"/customers/#{customer}")

      assert html =~ "Show Customer"
      assert html =~ customer.name
    end

    test "updates customer and returns to show", %{conn: conn, customer: customer} do
      {:ok, show_live, _html} = live(conn, ~p"/customers/#{customer}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/customers/#{customer}/edit?return_to=show")

      assert render(form_live) =~ "Edit Customer"

      assert form_live
             |> form("#customer-form", customer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#customer-form", customer: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/customers/#{customer}")

      html = render(show_live)
      assert html =~ "Customer updated successfully"
      assert html =~ "some updated name"
    end
  end
end
