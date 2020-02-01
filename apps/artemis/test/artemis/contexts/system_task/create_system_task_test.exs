defmodule Artemis.CreateSystemTaskTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateSystemTask

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateSystemTask.call!(%{}, Mock.system_user())
      end
    end

    test "starts a system task when passed valid params" do
      params = params_for(:system_task)

      %Task{} = CreateSystemTask.call!(params, Mock.system_user())
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateSystemTask.call(%{}, Mock.system_user())

      assert errors_on(changeset).type == ["can't be blank"]
    end

    test "starts a system task when passed valid params" do
      params = params_for(:system_task)

      {:ok, %Task{}} = CreateSystemTask.call(params, Mock.system_user())
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      system_task = params_for(:system_task)

      {:ok, %Task{}} = CreateSystemTask.call(system_task, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "system-task:created"
      }
    end
  end
end
