defmodule Artemis.UpdateCloudTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateCloud

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:cloud)

      assert_raise Artemis.Context.Error, fn ->
        UpdateCloud.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      cloud = insert(:cloud)
      params = %{}

      updated = UpdateCloud.call!(cloud, params, Mock.system_user())

      assert updated.name == cloud.name
    end

    test "updates a record when passed valid params" do
      cloud = insert(:cloud)
      params = params_for(:cloud)

      updated = UpdateCloud.call!(cloud, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      cloud = insert(:cloud)
      params = params_for(:cloud)

      updated = UpdateCloud.call!(cloud.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:cloud)

      {:error, _} = UpdateCloud.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      cloud = insert(:cloud)
      params = %{}

      {:ok, updated} = UpdateCloud.call(cloud, params, Mock.system_user())

      assert updated.name == cloud.name
    end

    test "updates a record when passed valid params" do
      cloud = insert(:cloud)
      params = params_for(:cloud)

      {:ok, updated} = UpdateCloud.call(cloud, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      cloud = insert(:cloud)
      params = params_for(:cloud)

      {:ok, updated} = UpdateCloud.call(cloud.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      cloud = insert(:cloud)
      params = params_for(:cloud)

      {:ok, updated} = UpdateCloud.call(cloud, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "cloud:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
