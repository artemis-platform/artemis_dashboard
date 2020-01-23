defmodule Artemis.MachineTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Cloud
  alias Artemis.Customer
  alias Artemis.DataCenter
  alias Artemis.Machine

  @preload [:cloud, :customer, :data_center]

  describe "attributes - constraints" do
    test "slug must be unique" do
      existing = insert(:machine)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:machine, slug: existing.slug)
      end
    end
  end

  describe "associations - cloud" do
    setup do
      cloud = insert(:cloud)
      machine = hd(cloud.machines)

      {:ok, cloud: cloud, machine: Repo.preload(machine, @preload)}
    end

    test "update association", %{cloud: cloud, machine: machine} do
      new_cloud = insert(:cloud)

      assert machine.cloud_id == cloud.id

      {:ok, updated} =
        machine
        |> Machine.associations_changeset(%{cloud: new_cloud})
        |> Repo.update()

      updated = Repo.preload(updated, @preload)

      assert updated.cloud_id == new_cloud.id
    end

    test "deleting association does not delete record", %{cloud: cloud, machine: machine} do
      assert Repo.get(Machine, machine.id) != nil
      assert machine.cloud_id != nil

      Repo.delete(cloud)

      machine =
        Machine
        |> preload(^@preload)
        |> Repo.get(machine.id)

      assert machine != nil
      assert machine.cloud_id == nil
    end

    test "deleting association nilifies association", %{cloud: cloud, machine: machine} do
      cloud = Repo.preload(cloud, [:machines])
      machine_ids = Enum.map(cloud.machines, & &1.id)

      assert Enum.member?(machine_ids, machine.id)

      Repo.delete(machine)

      assert Repo.get(Machine, machine.id) == nil

      cloud =
        Cloud
        |> preload([:machines])
        |> Repo.get(cloud.id)

      machine_ids = Enum.map(cloud.machines, & &1.id)

      assert Enum.member?(machine_ids, machine.id) == false
    end
  end

  describe "associations - data_center" do
    setup do
      machine = insert(:machine)
      data_center = machine.data_center

      {:ok, data_center: data_center, machine: Repo.preload(machine, @preload)}
    end

    test "update association", %{data_center: data_center, machine: machine} do
      new_data_center = insert(:data_center)

      assert machine.data_center_id == data_center.id

      {:ok, updated} =
        machine
        |> Machine.associations_changeset(%{data_center: new_data_center})
        |> Repo.update()

      updated = Repo.preload(updated, @preload)

      assert updated.data_center_id == new_data_center.id
    end

    test "deleting association does not delete record", %{data_center: data_center, machine: machine} do
      assert Repo.get(Machine, machine.id) != nil
      assert machine.data_center_id != nil

      Repo.delete(data_center)

      machine =
        Machine
        |> preload(^@preload)
        |> Repo.get(machine.id)

      assert machine != nil
      assert machine.data_center_id == nil
    end

    test "deleting association nilifies association", %{data_center: data_center, machine: machine} do
      data_center = Repo.preload(data_center, [:machines])
      machine_ids = Enum.map(data_center.machines, & &1.id)

      assert Enum.member?(machine_ids, machine.id)

      Repo.delete(machine)

      assert Repo.get(Machine, machine.id) == nil

      data_center =
        DataCenter
        |> preload([:machines])
        |> Repo.get(data_center.id)

      machine_ids = Enum.map(data_center.machines, & &1.id)

      assert Enum.member?(machine_ids, machine.id) == false
    end
  end

  describe "associations - customers" do
    setup do
      customer = insert(:customer)
      cloud = insert(:cloud, customer: customer)
      machine = hd(cloud.machines)

      {:ok, machine: Repo.preload(machine, @preload)}
    end

    test "deleting association does not remove record", %{machine: machine} do
      assert Repo.get(Machine, machine.id) != nil
      assert machine.cloud != nil
      assert machine.customer != nil

      Repo.delete(machine.customer)

      machine =
        Machine
        |> preload(^@preload)
        |> Repo.get(machine.id)

      assert machine != nil
      assert machine.cloud != nil
      assert machine.customer == nil
    end

    test "deleting record nilifies associations", %{machine: machine} do
      customer = Repo.preload(machine.customer, [:machines])
      machine_ids = Enum.map(customer.machines, & &1.id)

      assert Enum.member?(machine_ids, machine.id)

      Repo.delete(machine)

      customer =
        Customer
        |> preload([:machines])
        |> Repo.get(customer.id)

      machine_ids = Enum.map(customer.machines, & &1.id)

      assert customer != nil
      assert Enum.member?(machine_ids, machine.id) == false
    end
  end
end
