defmodule Artemis.CreateCloudTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateCloud

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateCloud.call!(%{}, Mock.system_user())
      end
    end

    test "creates a cloud when passed valid params" do
      params = params_for(:cloud)

      cloud = CreateCloud.call!(params, Mock.system_user())

      assert cloud.name == params.name
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateCloud.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a cloud when passed valid params" do
      params = params_for(:cloud)

      {:ok, cloud} = CreateCloud.call(params, Mock.system_user())

      assert cloud.name == params.name
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, cloud} = CreateCloud.call(params_for(:cloud), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "cloud:created",
        payload: %{
          data: ^cloud
        }
      }
    end
  end
end
