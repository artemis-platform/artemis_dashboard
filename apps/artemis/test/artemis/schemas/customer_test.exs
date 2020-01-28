defmodule Artemis.CustomerTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Cloud
  alias Artemis.Customer
  alias Artemis.DataCenter
  alias Artemis.Machine

  @preload [:clouds, :data_centers, :machines]

  describe "attributes - constraints" do
    test "name must be unique" do
      existing = insert(:customer)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:customer, name: existing.name)
      end
    end
  end

  describe "associations - clouds" do
    setup do
      customer = insert(:customer)

      insert_list(3, :cloud, customer: customer)

      {:ok, customer: Repo.preload(customer, @preload)}
    end

    test "deleting association does not remove record", %{customer: customer} do
      assert Repo.get(Customer, customer.id) != nil
      assert length(customer.clouds) == 3

      Enum.map(customer.clouds, &Repo.delete(&1))

      customer =
        Customer
        |> preload(^@preload)
        |> Repo.get(customer.id)

      assert Repo.get(Customer, customer.id) != nil
      assert length(customer.clouds) == 0
    end

    test "deleting record nilifies associations", %{customer: customer} do
      assert Repo.get(Customer, customer.id) != nil
      assert length(customer.clouds) == 3

      Enum.map(customer.clouds, fn cloud ->
        record = Repo.get(Cloud, cloud.id)

        assert record != nil
        assert record.customer_id != nil
      end)

      Repo.delete(customer)

      assert Repo.get(Customer, customer.id) == nil

      Enum.map(customer.clouds, fn cloud ->
        record = Repo.get(Cloud, cloud.id)

        assert record != nil
        assert record.customer_id == nil
      end)
    end
  end

  describe "associations - data centers" do
    setup do
      customer = insert(:customer)

      insert(:cloud, customer: customer)

      {:ok, customer: Repo.preload(customer, @preload)}
    end

    test "deleting association does not remove record", %{customer: customer} do
      assert Repo.get(Customer, customer.id) != nil
      assert length(customer.machines) == 3
      assert length(customer.data_centers) == 3

      Enum.map(customer.data_centers, &Repo.delete(&1))

      customer =
        Customer
        |> preload(^@preload)
        |> Repo.get(customer.id)

      assert customer != nil
      assert length(customer.machines) == 3
      assert length(customer.data_centers) == 0
    end

    test "deleting record nilifies associations", %{customer: customer} do
      data_center =
        customer.data_centers
        |> hd()
        |> Repo.preload([:customers])

      customer_ids = Enum.map(data_center.customers, & &1.id)

      assert Enum.member?(customer_ids, customer.id)

      Repo.delete(customer)

      data_center =
        DataCenter
        |> preload([:customers])
        |> Repo.get(data_center.id)

      customer_ids = Enum.map(data_center.customers, & &1.id)

      assert data_center != nil
      assert Enum.member?(customer_ids, customer.id) == false
    end
  end

  describe "associations - machines" do
    setup do
      customer = insert(:customer)

      insert(:cloud, customer: customer)

      {:ok, customer: Repo.preload(customer, @preload)}
    end

    test "deleting association does not remove record", %{customer: customer} do
      assert Repo.get(Customer, customer.id) != nil
      assert length(customer.machines) == 3

      Enum.map(customer.machines, &Repo.delete(&1))

      customer =
        Customer
        |> preload(^@preload)
        |> Repo.get(customer.id)

      assert customer != nil
      assert length(customer.machines) == 0
    end

    test "deleting record nilifies associations", %{customer: customer} do
      machine =
        customer.machines
        |> hd()
        |> Repo.preload([:customer])

      assert machine.customer.id == customer.id

      Repo.delete(customer)

      machine =
        Machine
        |> preload([:customer])
        |> Repo.get(machine.id)

      assert machine != nil
      assert machine.customer == nil
    end
  end
end
