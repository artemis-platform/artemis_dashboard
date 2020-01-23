defmodule Artemis.DataCenterTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Cloud
  alias Artemis.Customer
  alias Artemis.DataCenter
  alias Artemis.Machine

  @preload [:clouds, :customers, :machines]

  describe "attributes - constraints" do
    test "slug must be unique" do
      existing = insert(:data_center)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:data_center, slug: existing.slug)
      end
    end
  end

  describe "associations - customers" do
    setup do
      data_center = insert(:data_center)
      machines = insert_list(3, :machine, data_center: data_center)
      cloud = insert(:cloud, machines: machines)
      _customer = insert(:customer, clouds: [cloud])

      {:ok, data_center: Repo.preload(data_center, @preload)}
    end

    test "deleting association does not delete record", %{data_center: data_center} do
      assert Repo.get(DataCenter, data_center.id) != nil
      assert length(data_center.machines) == 3
      assert length(data_center.clouds) == 1
      assert length(data_center.customers) == 1

      Enum.map(data_center.customers, &Repo.delete(&1))

      data_center =
        DataCenter
        |> preload(^@preload)
        |> Repo.get(data_center.id)

      assert data_center != nil
      assert length(data_center.machines) == 3
      assert length(data_center.clouds) == 1
      assert length(data_center.customers) == 0
    end

    test "deleting association nilifies association", %{data_center: data_center} do
      customer =
        data_center.customers
        |> hd()
        |> Repo.preload([:data_centers])

      assert length(customer.data_centers) == 1
      assert hd(customer.data_centers).id == data_center.id

      Repo.delete(data_center)

      customer =
        Customer
        |> preload([:data_centers])
        |> Repo.get(customer.id)

      assert customer != nil
      assert length(customer.data_centers) == 0
    end
  end

  describe "associations - clouds" do
    setup do
      data_center = insert(:data_center)
      machines = insert_list(3, :machine, data_center: data_center)
      _cloud = insert(:cloud, machines: machines)

      {:ok, data_center: Repo.preload(data_center, @preload)}
    end

    test "deleting association does not delete record", %{data_center: data_center} do
      assert Repo.get(DataCenter, data_center.id) != nil
      assert length(data_center.machines) == 3
      assert length(data_center.clouds) == 1

      Enum.map(data_center.clouds, &Repo.delete(&1))

      data_center =
        DataCenter
        |> preload(^@preload)
        |> Repo.get(data_center.id)

      assert data_center != nil
      assert length(data_center.clouds) == 0
    end

    test "deleting association nilifies association", %{data_center: data_center} do
      cloud =
        data_center.clouds
        |> hd()
        |> Repo.preload([:data_centers])

      assert length(cloud.data_centers) == 1
      assert hd(cloud.data_centers).id == data_center.id

      Repo.delete(data_center)

      cloud =
        Cloud
        |> preload([:data_centers])
        |> Repo.get(cloud.id)

      assert cloud != nil
      assert length(cloud.data_centers) == 0
    end
  end

  describe "associations - machines" do
    setup do
      data_center = insert(:data_center)

      insert_list(3, :machine, data_center: data_center)

      {:ok, data_center: Repo.preload(data_center, @preload)}
    end

    test "deleting association does not delete record", %{data_center: data_center} do
      assert Repo.get(DataCenter, data_center.id) != nil
      assert length(data_center.machines) == 3

      Enum.map(data_center.machines, &Repo.delete(&1))

      data_center =
        DataCenter
        |> preload(^@preload)
        |> Repo.get(data_center.id)

      assert data_center != nil
      assert length(data_center.machines) == 0
    end

    test "deleting association nilifies association", %{data_center: data_center} do
      machine =
        data_center.machines
        |> hd()
        |> Repo.preload([:data_center])

      assert machine.data_center.id == data_center.id

      Repo.delete(data_center)

      machine =
        Machine
        |> preload([:data_center])
        |> Repo.get(machine.id)

      assert machine != nil
      assert machine.data_center == nil
    end
  end
end
