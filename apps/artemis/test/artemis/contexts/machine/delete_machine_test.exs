defmodule Artemis.DeleteMachineTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Machine
  alias Artemis.DeleteMachine

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteMachine.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:machine)

      %Machine{} = DeleteMachine.call!(record, Mock.system_user())

      assert Repo.get(Machine, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:machine)

      %Machine{} = DeleteMachine.call!(record.id, Mock.system_user())

      assert Repo.get(Machine, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteMachine.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:machine)

      {:ok, _} = DeleteMachine.call(record, Mock.system_user())

      assert Repo.get(Machine, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:machine)

      {:ok, _} = DeleteMachine.call(record.id, Mock.system_user())

      assert Repo.get(Machine, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, machine} = DeleteMachine.call(insert(:machine), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "machine:deleted",
        payload: %{
          data: ^machine
        }
      }
    end
  end
end
