defmodule Artemis.DeleteFeatureTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Feature
  alias Artemis.DeleteFeature

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteFeature.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:feature)

      %Feature{} = DeleteFeature.call!(record, Mock.system_user())

      assert Repo.get(Feature, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:feature)

      %Feature{} = DeleteFeature.call!(record.id, Mock.system_user())

      assert Repo.get(Feature, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteFeature.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:feature)

      {:ok, _} = DeleteFeature.call(record, Mock.system_user())

      assert Repo.get(Feature, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:feature)

      {:ok, _} = DeleteFeature.call(record.id, Mock.system_user())

      assert Repo.get(Feature, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, feature} = DeleteFeature.call(insert(:feature), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "feature:deleted",
        payload: %{
          data: ^feature
        }
      }
    end

    test "does not publish if explicitly disabled" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      record = insert(:feature)

      params = %{
        broadcast: false
      }

      {:ok, feature} = DeleteFeature.call(record, params, Mock.system_user())

      refute_received %Phoenix.Socket.Broadcast{
        event: "feature:deleted",
        payload: %{
          data: ^feature
        }
      }
    end
  end
end
