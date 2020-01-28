defmodule Artemis.UpdateDataCenterTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateDataCenter

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:data_center)

      assert_raise Artemis.Context.Error, fn ->
        UpdateDataCenter.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      data_center = insert(:data_center)
      params = %{}

      updated = UpdateDataCenter.call!(data_center, params, Mock.system_user())

      assert updated.name == data_center.name
    end

    test "updates a record when passed valid params" do
      data_center = insert(:data_center)
      params = params_for(:data_center)

      updated = UpdateDataCenter.call!(data_center, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      data_center = insert(:data_center)
      params = params_for(:data_center)

      updated = UpdateDataCenter.call!(data_center.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:data_center)

      {:error, _} = UpdateDataCenter.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      data_center = insert(:data_center)
      params = %{}

      {:ok, updated} = UpdateDataCenter.call(data_center, params, Mock.system_user())

      assert updated.name == data_center.name
    end

    test "updates a record when passed valid params" do
      data_center = insert(:data_center)
      params = params_for(:data_center)

      {:ok, updated} = UpdateDataCenter.call(data_center, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      data_center = insert(:data_center)
      params = params_for(:data_center)

      {:ok, updated} = UpdateDataCenter.call(data_center.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      data_center = insert(:data_center)
      params = params_for(:data_center)

      {:ok, updated} = UpdateDataCenter.call(data_center, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "data-center:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
