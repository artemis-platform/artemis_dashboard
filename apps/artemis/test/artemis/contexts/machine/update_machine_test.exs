defmodule Artemis.UpdateMachineTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateMachine

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:machine)

      assert_raise Artemis.Context.Error, fn ->
        UpdateMachine.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      machine = insert(:machine)
      params = %{}

      updated = UpdateMachine.call!(machine, params, Mock.system_user())

      assert updated.name == machine.name
    end

    test "updates a record when passed valid params" do
      machine = insert(:machine)
      params = params_for(:machine)

      updated = UpdateMachine.call!(machine, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      machine = insert(:machine)
      params = params_for(:machine)

      updated = UpdateMachine.call!(machine.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:machine)

      {:error, _} = UpdateMachine.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      machine = insert(:machine)
      params = %{}

      {:ok, updated} = UpdateMachine.call(machine, params, Mock.system_user())

      assert updated.name == machine.name
    end

    test "updates a record when passed valid params" do
      machine = insert(:machine)
      params = params_for(:machine)

      {:ok, updated} = UpdateMachine.call(machine, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      machine = insert(:machine)
      params = params_for(:machine)

      {:ok, updated} = UpdateMachine.call(machine.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      machine = insert(:machine)
      params = params_for(:machine)

      {:ok, updated} = UpdateMachine.call(machine, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "machine:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
