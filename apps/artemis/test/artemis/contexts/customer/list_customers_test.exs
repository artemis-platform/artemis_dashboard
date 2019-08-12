defmodule Artemis.ListCustomersTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListCustomers
  alias Artemis.Repo
  alias Artemis.Customer

  setup do
    Repo.delete_all(Customer)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no customers exist" do
      assert ListCustomers.call(Mock.system_user()) == []
    end

    test "returns existing customer" do
      customer = insert(:customer)

      assert ListCustomers.call(Mock.system_user()) == [customer]
    end

    test "returns a list of customers" do
      count = 3
      insert_list(count, :customer)

      customers = ListCustomers.call(Mock.system_user())

      assert length(customers) == count
    end
  end

  describe "call - params" do
    setup do
      customer = insert(:customer)

      {:ok, customer: customer}
    end

    test "order" do
      insert_list(3, :customer)

      params = %{order: "name"}
      ascending = ListCustomers.call(params, Mock.system_user())

      params = %{order: "-name"}
      descending = ListCustomers.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListCustomers.call(params, Mock.system_user())
        |> Map.from_struct()
        |> Map.keys()

      pagination_keys = [
        :entries,
        :page_number,
        :page_size,
        :total_entries,
        :total_pages
      ]

      assert response_keys == pagination_keys
    end

    test "query - search" do
      insert(:customer, name: "Four Six", notes: "four-six")
      insert(:customer, name: "Four Two", notes: "four-two")
      insert(:customer, name: "Five Six", notes: "five-six")

      user = Mock.system_user()
      customers = ListCustomers.call(user)

      assert length(customers) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      customers = ListCustomers.call(params, user)

      assert length(customers) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      customers = ListCustomers.call(params, user)

      assert length(customers) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      customers = ListCustomers.call(params, user)

      assert length(customers) == 0
    end
  end
end
