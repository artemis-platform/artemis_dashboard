defmodule Artemis.GetMachineTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetMachine

  setup do
    machine = insert(:machine)

    {:ok, machine: machine}
  end

  describe "call" do
    test "returns nil machine not found" do
      invalid_id = 50_000_000

      assert GetMachine.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds machine by id", %{machine: machine} do
      assert GetMachine.call(machine.id, Mock.system_user()).id == machine.id
    end

    test "finds record by keyword list", %{machine: machine} do
      assert GetMachine.call([name: machine.name, slug: machine.slug], Mock.system_user()).id == machine.id
    end
  end

  describe "call!" do
    test "raises an exception machine not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetMachine.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds machine by id", %{machine: machine} do
      assert GetMachine.call!(machine.id, Mock.system_user()).id == machine.id
    end
  end
end
