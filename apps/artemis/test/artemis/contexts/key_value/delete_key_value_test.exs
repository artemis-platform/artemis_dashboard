defmodule Artemis.DeleteKeyValueTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.KeyValue
  alias Artemis.DeleteKeyValue

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteKeyValue.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:key_value)

      %KeyValue{} = DeleteKeyValue.call!(record, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:key_value)

      %KeyValue{} = DeleteKeyValue.call!(record.id, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end

    test "deletes a record when passed a key and valid params" do
      record = insert(:key_value)

      %KeyValue{} = DeleteKeyValue.call!(record.key, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteKeyValue.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:key_value)

      {:ok, _} = DeleteKeyValue.call(record, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:key_value)

      {:ok, _} = DeleteKeyValue.call(record.id, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end

    test "deletes a record when passed a key and valid params" do
      record = insert(:key_value)

      {:ok, _} = DeleteKeyValue.call(record.key, Mock.system_user())

      assert Repo.get(KeyValue, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, key_value} = DeleteKeyValue.call(insert(:key_value), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "key-value:deleted",
        payload: %{
          data: ^key_value
        }
      }
    end
  end
end
