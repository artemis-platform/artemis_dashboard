defmodule Artemis.CustomersTest do
  use Artemis.DataCase

  alias Artemis.Customers

  describe "customers" do
    alias Artemis.Customer

    import Artemis.AccountsFixtures, only: [user_scope_fixture: 0]
    import Artemis.CustomersFixtures

    @invalid_attrs %{name: nil, notes: nil}

    test "list/1 returns all scoped customers" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      customer = customer_fixture(scope)
      other_customer = customer_fixture(other_scope)
      assert Customers.list(scope) == [customer]
      assert Customers.list(other_scope) == [other_customer]
    end

    test "get!/2 returns the customer with given id" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)
      other_scope = user_scope_fixture()
      assert Customers.get!(scope, customer.id) == customer
      assert_raise Ecto.NoResultsError, fn -> Customers.get!(other_scope, customer.id) end
    end

    test "create/2 with valid data creates a customer" do
      valid_attrs = %{name: "some name", notes: "some notes"}
      scope = user_scope_fixture()

      assert {:ok, %Customer{} = customer} = Customers.create(scope, valid_attrs)
      assert customer.name == "some name"
      assert customer.notes == "some notes"
      assert customer.user_id == scope.user.id
    end

    test "create/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Customers.create(scope, @invalid_attrs)
    end

    test "update/3 with valid data updates the customer" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)
      update_attrs = %{name: "some updated name", notes: "some updated notes"}

      assert {:ok, %Customer{} = customer} = Customers.update(scope, customer, update_attrs)
      assert customer.name == "some updated name"
      assert customer.notes == "some updated notes"
    end

    test "update/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert_raise MatchError, fn ->
        Customers.update(other_scope, customer, %{})
      end
    end

    test "update/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Customers.update(scope, customer, @invalid_attrs)
      assert customer == Customers.get!(scope, customer.id)
    end

    test "delete/2 deletes the customer" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)
      assert {:ok, %Customer{}} = Customers.delete(scope, customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get!(scope, customer.id) end
    end

    test "delete/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      customer = customer_fixture(scope)
      assert_raise MatchError, fn -> Customers.delete(other_scope, customer) end
    end

    test "changeset/2 returns a customer changeset" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)
      assert %Ecto.Changeset{} = Customers.changeset(scope, customer)
    end
  end
end
