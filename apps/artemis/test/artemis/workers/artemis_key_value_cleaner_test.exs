defmodule Artemis.KeyValueCleanerTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.KeyValue
  alias Artemis.Worker.KeyValueCleaner

  @data []
  @config []

  describe "call" do
    test "returns empty list tuple when no records exist" do
      assert KeyValueCleaner.call(@data, @config) == {:ok, 0}
    end

    test "returns empty list tuple when no records are within filter" do
      future = insert(:key_value, expire_at: Timex.shift(Timex.now(), days: 1))

      assert KeyValueCleaner.call(@data, @config) == {:ok, 0}

      assert Repo.get(KeyValue, future.id) != nil
    end

    test "removes records within the date filter" do
      now = Timex.now()
      past = Timex.shift(now, days: -2)
      future = Timex.shift(now, days: 2)

      record_past = insert(:key_value, expire_at: past)
      record_now = insert(:key_value, expire_at: now)
      record_future = insert(:key_value, expire_at: future)
      record_nil = insert(:key_value, expire_at: nil)

      assert KeyValueCleaner.call(@data, @config) == {:ok, 2}

      assert Repo.get(KeyValue, record_past.id) == nil
      assert Repo.get(KeyValue, record_now.id) == nil
      assert Repo.get(KeyValue, record_future.id) != nil
      assert Repo.get(KeyValue, record_nil.id) != nil
    end
  end
end
