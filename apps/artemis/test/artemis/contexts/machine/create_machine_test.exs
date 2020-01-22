defmodule Artemis.CreateMachineTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateMachine

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateMachine.call!(%{}, Mock.system_user())
      end
    end

    test "creates a machine when passed valid params" do
      params = params_for(:machine)

      machine = CreateMachine.call!(params, Mock.system_user())

      assert machine.name == params.name
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateMachine.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a machine when passed valid params" do
      params = params_for(:machine)

      {:ok, machine} = CreateMachine.call(params, Mock.system_user())

      assert machine.name == params.name
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, machine} = CreateMachine.call(params_for(:machine), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "machine:created",
        payload: %{
          data: ^machine
        }
      }
    end
  end
end
