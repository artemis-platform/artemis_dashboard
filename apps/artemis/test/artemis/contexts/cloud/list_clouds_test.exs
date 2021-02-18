defmodule Artemis.ListCloudsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListClouds
  alias Artemis.Repo
  alias Artemis.Cloud

  setup do
    Repo.delete_all(Cloud)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no clouds exist" do
      assert ListClouds.call(Mock.system_user()) == []
    end

    test "returns existing cloud" do
      cloud = insert(:cloud)

      clouds = ListClouds.call(Mock.system_user())

      assert length(clouds) == 1
      assert hd(clouds).id == cloud.id
    end

    test "returns a list of clouds" do
      count = 3
      insert_list(count, :cloud)

      clouds = ListClouds.call(Mock.system_user())

      assert length(clouds) == count
    end
  end

  describe "call - params" do
    setup do
      cloud = insert(:cloud)

      {:ok, cloud: cloud}
    end

    test "order" do
      insert_list(3, :cloud)

      params = %{order: "name"}
      ascending = ListClouds.call(params, Mock.system_user())

      params = %{order: "-name"}
      descending = ListClouds.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListClouds.call(params, Mock.system_user())
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
      insert(:cloud, name: "Four Six", slug: "four-six")
      insert(:cloud, name: "Four Two", slug: "four-two")
      insert(:cloud, name: "Five Six", slug: "five-six")

      user = Mock.system_user()
      clouds = ListClouds.call(user)

      assert length(clouds) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      clouds = ListClouds.call(params, user)

      assert length(clouds) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      clouds = ListClouds.call(params, user)

      assert length(clouds) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      clouds = ListClouds.call(params, user)

      assert length(clouds) == 0
    end
  end

  describe "cache" do
    setup do
      ListClouds.reset_cache()
      ListClouds.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListClouds.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListClouds.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "uses default context cache options" do
      defaults = Artemis.CacheInstance.default_cache_options()
      cache_options = Artemis.CacheInstance.get_cache_options(ListClouds)

      assert cache_options[:expiration] == Keyword.fetch!(defaults, :expiration)
      assert cache_options[:limit] == Keyword.fetch!(defaults, :limit)
    end

    test "returns a cached result" do
      initial_call = ListClouds.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListClouds.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListClouds.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
