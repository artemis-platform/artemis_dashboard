defmodule Artemis.CustomersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Artemis.Customers` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        notes: "some notes"
      })

    {:ok, customer} = Artemis.Customers.create_customer(scope, attrs)
    customer
  end
end
