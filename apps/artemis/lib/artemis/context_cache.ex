defmodule Artemis.ContextCache do
  @moduledoc """
  Extends Context modules with cache functions

  ## Options

  Takes the following options:

    :cache_reset_on_cloudant_changes - Optional. List. Cloudant events that reset cache
    :cache_reset_on_events - Optional. List. Events that reset cache.
    :cache_driver - Optional. String. Allows a specific cache to use a different cache driver
      than the global default
    :cache_options - Optional. List. Options to pass to cache instance
    :cache_key - Optional. Atom or Function. See section about Cache Keys.
    :rescue - Optional. Boolean. When set to true, rescues from exceptions in
      the `call()` function and returns a generic `{:error, _} tuple

  ## Cache Keys

  A single cache instance can store many values under different keys. By
  default, a simple cache key based on the passed parameters is used.

  For example, these calls are stored under different keys:

      MyApp.ExampleContext.call_with_cache(%{page: 1})
      MyApp.ExampleContext.call_with_cache(%{page: 200})

  By default, the simple cache key treats all users equally. As long as the
  parameters match, the same data is returned:

      MyApp.ExampleContext.call_with_cache(%{page: 1}, user_1)
      MyApp.ExampleContext.call_with_cache(%{page: 1}, user_2)

  Typically, permissions are checked before a cache is called. And that
  upstream code determines whether a user has access to the context or not.

  But there are cases where the user's permissions are also used within the
  context to return different results.

  For example, an admin user may be able to see a list of all resources, where
  normal users can only see resources related to their user.

  In these cases, a more complex cache key that includes the user's
  permissions is needed.

  ### Complex and Custom Cache Keys

  There are two options to implement a cache key that takes into account the
  user's permission.

  The first way is to use the built-in key generator by passing the
  `cache_key` option:

      defmodule MyApp.ExampleContext do
        use MyApp.ContextCache,
          cache_key: :complex
      end

  This generic built-in collects all of the users permissions and includes them in the
  cache key. While effective, the same data may be cached under different keys
  because the built-in function does not understand which of the user's many
  permissions determine the context output.

  A better approach is to define a custom cache option:

      defmodule MyApp.ExampleContext do
        use MyApp.ContextCache,
          cache_key: &custom_cache_key/1

        def custom_cache_key(args) do
          # custom code here
        end
      end

  The custom cache key can filter user permissions to the exact ones used
  within the context. This fine-grained control can ensure users only have
  access to the proper data while also minimizing the amount of duplicate
  values in the cache.
  """

  defmacro __using__(options) do
    quote do
      import Artemis.ContextCache

      alias Artemis.CacheInstance
      alias Artemis.Repo

      @default_rescue_option true

      @doc """
      Generic wrapper function to add caching around `call`

      If a cache entry already exists, it returns it. Otherwise, it fetches the
      data, caches it, and returns it.
      """
      def call_with_cache(), do: fetch_cached([])
      def call_with_cache(arg1), do: fetch_cached([arg1])
      def call_with_cache(arg1, arg2), do: fetch_cached([arg1, arg2])
      def call_with_cache(arg1, arg2, arg3), do: fetch_cached([arg1, arg2, arg3])
      def call_with_cache(arg1, arg2, arg3, arg4), do: fetch_cached([arg1, arg2, arg3, arg4])
      def call_with_cache(arg1, arg2, arg3, arg4, arg5), do: fetch_cached([arg1, arg2, arg3, arg4, arg5])

      @doc """
      Generic wrapper function to add caching around `call`

      Always fetches the latest data, caches it, and returns it.
      """
      def call_and_update_cache(), do: update_cache([])
      def call_and_update_cache(arg1), do: update_cache([arg1])
      def call_and_update_cache(arg1, arg2), do: update_cache([arg1, arg2])
      def call_and_update_cache(arg1, arg2, arg3), do: update_cache([arg1, arg2, arg3])
      def call_and_update_cache(arg1, arg2, arg3, arg4), do: update_cache([arg1, arg2, arg3, arg4])
      def call_and_update_cache(arg1, arg2, arg3, arg4, arg5), do: update_cache([arg1, arg2, arg3, arg4, arg5])

      @doc """
      Generic wrapper function to add caching around `call`

      If a cache entry exists, it returns the cached value and asynchronously
      starts a job to update the cache. The updated value is not returned

      If the cache entry does not exist, it fetches the data, caches it, and
      returns it.
      """
      def call_with_cache_then_update(), do: get_cached_then_update([])
      def call_with_cache_then_update(arg1), do: get_cached_then_update([arg1])
      def call_with_cache_then_update(arg1, arg2), do: get_cached_then_update([arg1, arg2])
      def call_with_cache_then_update(arg1, arg2, arg3), do: get_cached_then_update([arg1, arg2, arg3])
      def call_with_cache_then_update(arg1, arg2, arg3, arg4), do: get_cached_then_update([arg1, arg2, arg3, arg4])

      def call_with_cache_then_update(arg1, arg2, arg3, arg4, arg5),
        do: get_cached_then_update([arg1, arg2, arg3, arg4, arg5])

      @doc """
      Clear all values from cache. Returns successfully if cache is not started.
      """
      def reset_cache() do
        case Artemis.CacheInstance.started?(__MODULE__) do
          true -> {:ok, Artemis.CacheInstance.reset(__MODULE__)}
          false -> {:ok, :cache_not_started}
        end
      end

      # Helpers

      defp fetch_cached(args) do
        {:ok, _} = create_cache()

        getter = fn -> execute_call(args) end
        key = get_cache_key(args)

        Artemis.CacheInstance.fetch(__MODULE__, key, getter)
      rescue
        error in MatchError -> handle_match_error(error, args, &fetch_cached/1)
      end

      defp update_cache(args) do
        {:ok, _} = create_cache()

        result = execute_call(args)
        key = get_cache_key(args)

        Artemis.CacheInstance.put(__MODULE__, key, result)
      rescue
        error in MatchError -> handle_match_error(error, args, &update_cache/1)
      end

      defp get_cached_then_update(args) do
        {:ok, _} = create_cache()

        getter = fn -> execute_call(args) end
        key = get_cache_key(args)

        case Artemis.CacheInstance.get(__MODULE__, key) do
          nil ->
            fetch_cached(args)

          response ->
            Task.start_link(fn -> update_cache(args) end)
            response
        end
      rescue
        error in MatchError -> handle_match_error(error, args, &update_cache/1)
      end

      defp execute_call(args) do
        apply(__MODULE__, :call, args)
      rescue
        error ->
          case Keyword.get(unquote(options), :rescue, @default_rescue_option) do
            true ->
              Artemis.Helpers.rescue_log(__STACKTRACE__, __MODULE__, error)
              {:error, "Error fetching cache data."}

            false ->
              reraise(error, __STACKTRACE__)
          end
      end

      defp handle_match_error(%MatchError{term: {:error, {:already_started, _}}}, args, callback) do
        # The CacheInstance contains two linked processes, a cache GenServer and a
        # cache instance. The GenServer starts a linked cache instance on initialization.
        #
        # Depending on the cache driver being used, there may be a race
        # condition when the GenServer is started and the cache instance is still in the
        # process of starting. If multiple requests are sent at the same time, it may
        # result in multiple cache instances being started. The first instance to
        # complete will succeed and all other requests will fail with an
        # `:already_started` error message.
        #
        # Since a cache instance is now running, resending the request to the
        # GenServer will succeed.
        #
        callback.(args)
      end

      defp handle_match_error(_error, args) do
        # The CacheInstance contains two linked processes, a cache GenServer and a
        # cache instance. When a CacheInstance is reset, the cache GenServer is
        # stopped. Because they are linked, shortly after the cache instance is also
        # stopped.
        #
        # Depending on the cache driver being used, there may be a race
        # condition when the GenServer is stopped and the cache instance is
        # still in the process of stopping. If a new cache request is received during
        # that window of time, the new cache GenServer will fail when trying to start a
        # linked cache instance because the cache registered name is unavailable.
        #
        # This race condition is primarily hit in test scenarios, but could occur in
        # production under a heavy request load.
        #
        # Instead of trying to resolve the race condition, let it crash. Return a valid
        # uncached result in the meantime. Future requests after this window closes will
        # successfully create a dynamic cache.
        #
        %Artemis.CacheInstance.CacheEntry{data: apply(__MODULE__, :call, args)}
      end

      defp create_cache() do
        case CacheInstance.exists?(__MODULE__) do
          true ->
            {:ok, "Cache already exists"}

          false ->
            child_options = [
              cache_reset_on_cloudant_changes: Keyword.get(unquote(options), :cache_reset_on_cloudant_changes, []),
              cache_reset_on_events: Keyword.get(unquote(options), :cache_reset_on_events, []),
              cache_driver: Keyword.get(unquote(options), :cache_driver),
              cache_options: Keyword.get(unquote(options), :cache_options, []),
              module: __MODULE__
            ]

            Artemis.CacheSupervisor.start_child(child_options)
        end
      end

      defp get_cache_key(args) do
        case Keyword.get(unquote(options), :cache_key, :simple) do
          :complex -> get_built_in_cache_key_complex(args)
          :simple -> get_built_in_cache_key_simple(args)
          custom -> custom.(args)
        end
      end

      defp get_built_in_cache_key_complex(args) do
        %{
          other_args: get_non_user_args(args),
          user_permissions: get_user_permissions(args)
        }
      end

      defp get_built_in_cache_key_simple(args), do: get_non_user_args(args)

      defp get_user_permissions(args) do
        args
        |> get_user_arg()
        |> Artemis.Repo.preload([:permissions])
        |> Map.get(:permissions)
        |> Enum.map(& &1.slug)
        |> Enum.sort()
      end

      defp get_user_arg(args) do
        default = %Artemis.User{permissions: []}

        args
        |> Enum.reverse()
        |> Enum.find(default, &user?(&1))
      end

      defp get_non_user_args(args) do
        index =
          args
          |> Enum.reverse()
          |> Enum.find_index(&user?(&1))

        case index do
          nil ->
            args

          _ ->
            args
            |> Enum.reverse()
            |> List.delete_at(index)
            |> Enum.reverse()
        end
      end

      defp user?(value), do: is_map(value) && Map.get(value, :__struct__) && value.__struct__ == Artemis.User
    end
  end
end
