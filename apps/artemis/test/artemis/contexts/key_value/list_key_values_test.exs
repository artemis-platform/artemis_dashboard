defmodule Artemis.ListKeyValuesTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListKeyValues
  alias Artemis.Repo
  alias Artemis.KeyValue

  setup do
    Repo.delete_all(KeyValue)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no key_values exist" do
      assert ListKeyValues.call(Mock.system_user()) == []
    end

    test "returns existing key_value" do
      key_value = insert(:key_value)

      assert ListKeyValues.call(Mock.system_user()) == [key_value]
    end

    test "returns a list of key_values" do
      count = 3
      insert_list(count, :key_value)

      key_values = ListKeyValues.call(Mock.system_user())

      assert length(key_values) == count
    end
  end

  describe "call - params" do
    setup do
      key_value = insert(:key_value)

      {:ok, key_value: key_value}
    end

    test "order" do
      insert_list(3, :key_value)

      params = %{order: "key"}
      ascending = ListKeyValues.call(params, Mock.system_user())

      params = %{order: "-key"}
      descending = ListKeyValues.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListKeyValues.call(params, Mock.system_user())
        |> Map.from_struct()
        |> Map.keys()

      pagination_keys = [
        :entries,
        :page_number,
        :page_size,
        :total_entries,
        :total_pages
      ]

      assert response_keys == pagination_keys
    end
  end

  describe "cache" do
    setup do
      ListKeyValues.reset_cache()
      ListKeyValues.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListKeyValues.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListKeyValues.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "returns a cached result" do
      initial_call = ListKeyValues.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListKeyValues.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListKeyValues.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
