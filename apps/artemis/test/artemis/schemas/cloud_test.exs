defmodule Artemis.CloudTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Cloud
  alias Artemis.Customer
  alias Artemis.DataCenter
  alias Artemis.Machine

  @preload [:customer, :data_centers, :machines]

  describe "attributes - constraints" do
    test "slug must be unique" do
      existing = insert(:cloud)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:cloud, slug: existing.slug)
      end
    end
  end

  describe "associations - customer" do
    setup do
      cloud = insert(:cloud)
      customer = cloud.customer

      {:ok, cloud: Repo.preload(cloud, @preload), customer: customer}
    end

    test "update association", %{cloud: cloud, customer: customer} do
      new_customer = insert(:customer)

      assert cloud.customer_id == customer.id

      {:ok, updated} =
        cloud
        |> Cloud.associations_changeset(%{customer: new_customer})
        |> Repo.update()

      updated = Repo.preload(updated, @preload)

      assert updated.customer_id == new_customer.id
    end

    test "deleting association does not delete record", %{cloud: cloud, customer: customer} do
      assert Repo.get(Cloud, cloud.id) != nil
      assert cloud.customer_id != nil

      Repo.delete(customer)

      cloud =
        Cloud
        |> preload(^@preload)
        |> Repo.get(cloud.id)

      assert cloud != nil
      assert cloud.customer_id == nil
    end

    test "deleting association nilifies association", %{cloud: cloud, customer: customer} do
      customer = Repo.preload(customer, [:clouds])
      cloud_ids = Enum.map(customer.clouds, & &1.id)

      assert Enum.member?(cloud_ids, cloud.id)

      Repo.delete(cloud)

      assert Repo.get(Cloud, cloud.id) == nil

      customer =
        Customer
        |> preload([:clouds])
        |> Repo.get(customer.id)

      cloud_ids = Enum.map(customer.clouds, & &1.id)

      assert Enum.member?(cloud_ids, cloud.id) == false
    end
  end

  describe "associations - data centers" do
    setup do
      cloud = insert(:cloud)

      {:ok, cloud: Repo.preload(cloud, @preload)}
    end

    test "deleting association does not remove record", %{cloud: cloud} do
      assert Repo.get(Cloud, cloud.id) != nil
      assert length(cloud.machines) == 3
      assert length(cloud.data_centers) == 3

      Enum.map(cloud.data_centers, &Repo.delete(&1))

      cloud =
        Cloud
        |> preload(^@preload)
        |> Repo.get(cloud.id)

      assert cloud != nil
      assert length(cloud.machines) == 3
      assert length(cloud.data_centers) == 0
    end

    test "deleting record nilifies associations", %{cloud: cloud} do
      data_center =
        cloud.data_centers
        |> hd()
        |> Repo.preload([:clouds])

      cloud_ids = Enum.map(data_center.clouds, & &1.id)

      assert Enum.member?(cloud_ids, cloud.id)

      Repo.delete(cloud)

      data_center =
        DataCenter
        |> preload([:clouds])
        |> Repo.get(data_center.id)

      cloud_ids = Enum.map(data_center.clouds, & &1.id)

      assert data_center != nil
      assert Enum.member?(cloud_ids, cloud.id) == false
    end
  end

  describe "associations - machines" do
    setup do
      cloud = insert(:cloud)

      {:ok, cloud: Repo.preload(cloud, @preload)}
    end

    test "deleting association does not remove record", %{cloud: cloud} do
      assert Repo.get(Cloud, cloud.id) != nil
      assert length(cloud.machines) == 3

      Enum.map(cloud.machines, &Repo.delete(&1))

      cloud =
        Cloud
        |> preload(^@preload)
        |> Repo.get(cloud.id)

      assert Repo.get(Cloud, cloud.id) != nil
      assert length(cloud.machines) == 0
    end

    test "deleting record nilifies associations", %{cloud: cloud} do
      assert Repo.get(Cloud, cloud.id) != nil
      assert length(cloud.machines) == 3

      Enum.map(cloud.machines, fn machine ->
        record = Repo.get(Machine, machine.id)

        assert record != nil
        assert record.cloud_id != nil
      end)

      Repo.delete(cloud)

      assert Repo.get(Cloud, cloud.id) == nil

      Enum.map(cloud.machines, fn machine ->
        record = Repo.get(Machine, machine.id)

        assert record != nil
        assert record.cloud_id == nil
      end)
    end
  end
end
