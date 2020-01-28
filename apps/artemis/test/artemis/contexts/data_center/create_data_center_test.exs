defmodule Artemis.CreateDataCenterTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateDataCenter

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateDataCenter.call!(%{}, Mock.system_user())
      end
    end

    test "creates a data center when passed valid params" do
      params = params_for(:data_center)

      data_center = CreateDataCenter.call!(params, Mock.system_user())

      assert data_center.name == params.name
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateDataCenter.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a data center when passed valid params" do
      params = params_for(:data_center)

      {:ok, data_center} = CreateDataCenter.call(params, Mock.system_user())

      assert data_center.name == params.name
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, data_center} = CreateDataCenter.call(params_for(:data_center), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "data-center:created",
        payload: %{
          data: ^data_center
        }
      }
    end
  end
end
