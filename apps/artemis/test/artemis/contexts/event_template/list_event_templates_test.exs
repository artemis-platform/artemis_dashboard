defmodule Artemis.ListEventTemplatesTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListEventTemplates
  alias Artemis.Repo
  alias Artemis.EventTemplate

  setup do
    Repo.delete_all(EventTemplate)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no event_templates exist" do
      assert ListEventTemplates.call(Mock.system_user()) == []
    end

    test "returns existing event_template" do
      event_template = insert(:event_template)

      event_templates = ListEventTemplates.call(Mock.system_user())

      assert length(event_templates) == 1
      assert hd(event_templates).id == event_template.id
    end

    test "returns a list of event_templates" do
      count = 3
      insert_list(count, :event_template)

      event_templates = ListEventTemplates.call(Mock.system_user())

      assert length(event_templates) == count
    end
  end

  describe "call - params" do
    setup do
      event_template = insert(:event_template)

      {:ok, event_template: event_template}
    end

    test "order" do
      insert_list(3, :event_template)

      params = %{order: "title"}
      ascending = ListEventTemplates.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListEventTemplates.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListEventTemplates.call(params, Mock.system_user())
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
      insert(:event_template, title: "Four Six")
      insert(:event_template, title: "Four Two")
      insert(:event_template, title: "Five Six")

      user = Mock.system_user()
      event_templates = ListEventTemplates.call(user)

      assert length(event_templates) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      event_templates = ListEventTemplates.call(params, user)

      assert length(event_templates) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      event_templates = ListEventTemplates.call(params, user)

      assert length(event_templates) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      event_templates = ListEventTemplates.call(params, user)

      assert length(event_templates) == 0
    end
  end

  describe "cache" do
    setup do
      ListEventTemplates.reset_cache()
      ListEventTemplates.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListEventTemplates.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListEventTemplates.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "uses default context cache options" do
      defaults = Artemis.CacheInstance.default_cachex_options()
      cachex_options = Artemis.CacheInstance.get_cachex_options(ListEventTemplates)

      assert cachex_options[:expiration] == Keyword.fetch!(defaults, :expiration)
      assert cachex_options[:limit] == Keyword.fetch!(defaults, :limit)
    end

    test "returns a cached result" do
      initial_call = ListEventTemplates.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListEventTemplates.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListEventTemplates.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
