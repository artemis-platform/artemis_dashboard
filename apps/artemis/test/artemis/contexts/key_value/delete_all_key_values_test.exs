defmodule Artemis.DeleteAllKeyValuesTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.DeleteAllKeyValues
  alias Artemis.KeyValue

  describe "call" do
    test "deletes all records when not passed params" do
      count = 3

      insert_list(count, :key_value)

      {:ok, total} = DeleteAllKeyValues.call(Mock.system_user())

      assert total == count
      assert Repo.all(KeyValue) == []
    end

    test "supports filter params - expire_at_lte" do
      now = Timex.now()
      past = Timex.shift(now, days: -2)
      future = Timex.shift(now, days: 2)

      record_past = insert(:key_value, expire_at: past)
      record_now = insert(:key_value, expire_at: now)
      record_future = insert(:key_value, expire_at: future)
      record_nil = insert(:key_value, expire_at: nil)

      params = %{
        filters: %{
          expire_at_lte: now
        }
      }

      {:ok, total} = DeleteAllKeyValues.call(params, Mock.system_user())

      assert total == 2
      assert Repo.get(KeyValue, record_past.id) == nil
      assert Repo.get(KeyValue, record_now.id) == nil
      assert Repo.get(KeyValue, record_future.id) != nil
      assert Repo.get(KeyValue, record_nil.id) != nil
    end

    test "supports filter params - id" do
      record_1 = insert(:key_value)
      record_2 = insert(:key_value)
      record_3 = insert(:key_value)

      params = %{
        filters: %{
          id: [record_1.id, record_2.id]
        }
      }

      {:ok, total} = DeleteAllKeyValues.call(params, Mock.system_user())

      assert total == 2
      assert Repo.get(KeyValue, record_1.id) == nil
      assert Repo.get(KeyValue, record_2.id) == nil
      assert Repo.get(KeyValue, record_3.id) != nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      count = 3

      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      insert_list(count, :key_value)

      {:ok, ^count} = DeleteAllKeyValues.call(Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "key-value:deleted:all",
        payload: %{
          data: %{records_deleted: count}
        }
      }
    end
  end
end
