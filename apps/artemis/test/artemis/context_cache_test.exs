defmodule Artemis.ContextCacheTest do
  use Artemis.DataCase

  defmodule DefaultContext do
    use Artemis.ContextCache

    def call(_params \\ %{}, _user), do: Ecto.UUID.generate()
  end

  defmodule CacheResetContext do
    use Artemis.ContextCache,
      cache_reset_on_cloudant_changes: [
        %{action: "tests:deleted", schema: "Test"}
      ],
      cache_reset_on_events: [
        "test:event"
      ]

    def call(_params \\ %{}, _user), do: true
  end

  defmodule ComplexContext do
    use Artemis.ContextCache,
      cache_key: :complex

    def call(_params \\ %{}, _user), do: true
  end

  defmodule CustomContext do
    use Artemis.ContextCache,
      cache_key: fn _args -> :custom_cache_key end

    def call(_params \\ %{}, _user), do: true
  end

  describe "cache keys" do
    test "default simple cache key" do
      user = Mock.system_user()
      key = DefaultContext.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = DefaultContext.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "complex cache key" do
      user = Mock.system_user()
      key = ComplexContext.call_with_cache(user).key

      assert is_map(key)
      assert Map.keys(key) == [:other_args, :user_permissions]
      assert key.other_args == []

      params = %{
        paginate: true
      }

      key = ComplexContext.call_with_cache(params, user).key

      assert is_map(key)
      assert Map.keys(key) == [:other_args, :user_permissions]
      assert key.other_args == [params]
    end

    test "custom cache key option" do
      user = Mock.system_user()
      key = CustomContext.call_with_cache(user).key

      assert is_atom(key)
      assert key == :custom_cache_key

      params = %{
        paginate: true
      }

      key = CustomContext.call_with_cache(params, user).key

      assert is_atom(key)
      assert key == :custom_cache_key
    end
  end

  describe "reset cache" do
    test "manually" do
      user = Mock.system_user()
      first_result = CacheResetContext.call_with_cache(user)
      second_result = CacheResetContext.call_with_cache(user)

      CacheResetContext.reset_cache()
      :timer.sleep(1_000)

      third_result = CacheResetContext.call_with_cache(user)

      assert first_result.inserted_at == second_result.inserted_at
      assert first_result.inserted_at != third_result.inserted_at
    end

    test "by event listener" do
      user = Mock.system_user()
      first_result = CacheResetContext.call_with_cache(user)
      second_result = CacheResetContext.call_with_cache(user)

      event_payload = %{
        test: "event-payload",
        type: "event"
      }

      Artemis.Event.broadcast(event_payload, "test:event", user)
      :timer.sleep(1_000)

      third_result = CacheResetContext.call_with_cache(user)

      assert first_result.inserted_at == second_result.inserted_at
      assert first_result.inserted_at != third_result.inserted_at
    end

    test "by cloudant event listener" do
      user = Mock.system_user()
      first_result = CacheResetContext.call_with_cache(user)
      second_result = CacheResetContext.call_with_cache(user)

      cloudant_change_payload = %{
        action: "tests:deleted",
        id: 1,
        schema: "Test"
      }

      Artemis.CloudantChange.broadcast(cloudant_change_payload)
      :timer.sleep(1_000)

      third_result = CacheResetContext.call_with_cache(user)

      assert first_result.inserted_at == second_result.inserted_at
      assert first_result.inserted_at != third_result.inserted_at
    end
  end

  describe "call with cache" do
    test "returns cached response if it exists, fetching then caching it if not" do
      user = Mock.system_user()

      first_result = DefaultContext.call_with_cache(user)
      second_result = DefaultContext.call_with_cache(user)

      DefaultContext.reset_cache()

      third_result = DefaultContext.call_with_cache(user)

      assert first_result.data == second_result.data
      assert first_result.data != third_result.data
    end
  end

  describe "call and update cache" do
    test "always fetches the latest data then caches it" do
      user = Mock.system_user()

      first_result = DefaultContext.call_and_update_cache(user)
      second_result = DefaultContext.call_and_update_cache(user)
      get_result = DefaultContext.call_with_cache(user)

      assert first_result.data != second_result.data
      assert second_result.data == get_result.data
    end
  end

  describe "call with cache then update" do
    test "if in cache, it returns current cached value and asynchronously updates cache for the next call" do
      user = Mock.system_user()

      set_cache_result = DefaultContext.call_with_cache(user)
      original_cached_result = DefaultContext.call_with_cache_then_update(user)

      :timer.sleep(1_000)

      updated_cached_result = DefaultContext.call_with_cache(user)

      assert original_cached_result.data == set_cache_result.data
      assert original_cached_result.data != updated_cached_result.data
    end

    test "if not in the cache, it fetches it, caches it, and returns it" do
      user = Mock.system_user()

      original_cached_result = DefaultContext.call_with_cache_then_update(user)
      original_get_result = DefaultContext.call_with_cache(user)

      second_cached_result = DefaultContext.call_with_cache_then_update(user)

      :timer.sleep(1_000)

      second_get_result = DefaultContext.call_with_cache(user)
      third_get_result = DefaultContext.call_with_cache(user)

      assert original_cached_result.data == original_get_result.data
      assert second_cached_result.data == original_get_result.data
      assert second_cached_result.data != second_get_result.data
      assert third_get_result.data == second_get_result.data
    end
  end
end
