defmodule Artemis.GetCustomerTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetCustomer

  setup do
    customer = insert(:customer)

    {:ok, customer: customer}
  end

  describe "call" do
    test "returns nil customer not found" do
      invalid_id = 50_000_000

      assert GetCustomer.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds customer by id", %{customer: customer} do
      assert GetCustomer.call(customer.id, Mock.system_user()) == customer
    end

    test "finds record by keyword list", %{customer: customer} do
      assert GetCustomer.call([name: customer.name], Mock.system_user()) == customer
    end
  end

  describe "call!" do
    test "raises an exception customer not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetCustomer.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds customer by id", %{customer: customer} do
      assert GetCustomer.call!(customer.id, Mock.system_user()) == customer
    end
  end
end
