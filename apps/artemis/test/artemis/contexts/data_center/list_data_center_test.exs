defmodule Artemis.ListDataCentersTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListDataCenters
  alias Artemis.Repo
  alias Artemis.DataCenter

  setup do
    Repo.delete_all(DataCenter)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no data centers exist" do
      assert ListDataCenters.call(Mock.system_user()) == []
    end

    test "returns existing data center" do
      data_center = insert(:data_center)

      data_centers = ListDataCenters.call(Mock.system_user())

      assert length(data_centers) == 1
      assert hd(data_centers).id == data_center.id
    end

    test "returns a list of data centers" do
      count = 3
      insert_list(count, :data_center)

      data_centers = ListDataCenters.call(Mock.system_user())

      assert length(data_centers) == count
    end
  end

  describe "call - params" do
    setup do
      data_center = insert(:data_center)

      {:ok, data_center: data_center}
    end

    test "order" do
      insert_list(3, :data_center)

      params = %{order: "name"}
      ascending = ListDataCenters.call(params, Mock.system_user())

      params = %{order: "-name"}
      descending = ListDataCenters.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListDataCenters.call(params, Mock.system_user())
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

    test "query - search" do
      insert(:data_center, name: "Four Six", slug: "four-six")
      insert(:data_center, name: "Four Two", slug: "four-two")
      insert(:data_center, name: "Five Six", slug: "five-six")

      user = Mock.system_user()
      data_centers = ListDataCenters.call(user)

      assert length(data_centers) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      data_centers = ListDataCenters.call(params, user)

      assert length(data_centers) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      data_centers = ListDataCenters.call(params, user)

      assert length(data_centers) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      data_centers = ListDataCenters.call(params, user)

      assert length(data_centers) == 0
    end
  end

  describe "cache" do
    setup do
      ListDataCenters.reset_cache()
      ListDataCenters.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListDataCenters.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListDataCenters.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "returns a cached result" do
      initial_call = ListDataCenters.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListDataCenters.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListDataCenters.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
