defmodule Artemis.ListMachinesTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListMachines
  alias Artemis.Repo
  alias Artemis.Machine

  setup do
    Repo.delete_all(Machine)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no machines exist" do
      assert ListMachines.call(Mock.system_user()) == []
    end

    test "returns existing machine" do
      machine = insert(:machine)

      machines = ListMachines.call(Mock.system_user())

      assert length(machines) == 1
      assert hd(machines).id == machine.id
    end

    test "returns a list of machines" do
      count = 3
      insert_list(count, :machine)

      machines = ListMachines.call(Mock.system_user())

      assert length(machines) == count
    end
  end

  describe "call - params" do
    setup do
      machine = insert(:machine)

      {:ok, machine: machine}
    end

    test "order" do
      insert_list(3, :machine)

      params = %{order: "name"}
      ascending = ListMachines.call(params, Mock.system_user())

      params = %{order: "-name"}
      descending = ListMachines.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListMachines.call(params, Mock.system_user())
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
      insert(:machine, name: "Four Six", slug: "four-six")
      insert(:machine, name: "Four Two", slug: "four-two")
      insert(:machine, name: "Five Six", slug: "five-six")

      user = Mock.system_user()
      machines = ListMachines.call(user)

      assert length(machines) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      machines = ListMachines.call(params, user)

      assert length(machines) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      machines = ListMachines.call(params, user)

      assert length(machines) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      machines = ListMachines.call(params, user)

      assert length(machines) == 0
    end
  end

  describe "cache" do
    setup do
      ListMachines.reset_cache()
      ListMachines.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListMachines.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListMachines.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "returns a cached result" do
      initial_call = ListMachines.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListMachines.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListMachines.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
