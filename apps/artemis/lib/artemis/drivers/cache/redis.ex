defmodule Artemis.Drivers.Cache.Redis do
  @moduledoc """
  Driver for Caching in Redis

  ## Implementation

  Unlike other drivers that have a unique cache storage per cache instance,
  Redis uses a single database. It prevents collisions by prefixing cache keys
  with the cache instance name, as defined in `get_cache_key/2` function.

  A separate Redis entry stores a list of keys for each cache entry using
  `store_cache_instance_cache_key/2`. These are used for operations like reset,
  allowing a "cache instance" to be reset without impacting other entries inside
  the same Redis database.
  """

  @default_expiration :timer.minutes(5)

  def get_cache_instance_options(options) do
    [
      expiration: Keyword.get(options, :expiration, @default_expiration),
      limit: Keyword.get(options, :limit, 100)
    ]
  end

  def create_cache_instance(_cache_instance_name, _options) do
    {:ok, :fake_pid_since_using_redis}
  end

  def get(cache_instance_name, key) do
    cache_key = get_cache_key(cache_instance_name, key)

    {:ok, response} = Artemis.RedisCacheConnectionPool.command(["GET", cache_key])

    decode(response)
  rescue
    _ -> nil
  end

  def put(cache_instance_name, key, entry, options \\ []) do
    cache_key = get_cache_key(cache_instance_name, key)
    cache_expiration = get_cache_expiration_in_seconds(options)
    cache_value = encode(entry)

    case is_number(cache_expiration) && cache_expiration > 0 do
      true -> Artemis.RedisCacheConnectionPool.command(["SETEX", cache_key, cache_expiration, cache_value])
      false -> Artemis.RedisCacheConnectionPool.command(["SET", cache_key, cache_value])
    end

    store_cache_instance_cache_key(cache_instance_name, cache_key)
  end

  @doc """
  Remove all entries for cache instance
  """
  def reset(cache_instance_name) do
    cache_instance_cache_keys = get_cache_instance_cache_keys(cache_instance_name) || []
    delete_cache_keys_commands = Enum.map(cache_instance_cache_keys, &["DEL", &1])

    case length(cache_instance_cache_keys) do
      0 ->
        {:ok, 0}

      size ->
        Artemis.RedisCacheConnectionPool.pipeline(delete_cache_keys_commands)
        Artemis.RedisCacheConnectionPool.command(["DEL", cache_instance_name])

        {:ok, size}
    end
  end

  defp get_cache_key(cache_instance_name, key) do
    encode({cache_instance_name, key})
  end

  defp store_cache_instance_cache_key(cache_instance_name, cache_key) do
    Artemis.RedisCacheConnectionPool.command(["LPUSH", cache_instance_name, cache_key])
  end

  defp get_cache_instance_cache_keys(cache_instance_name) do
    {:ok, cache_keys} = Artemis.RedisCacheConnectionPool.command(["LRANGE", cache_instance_name, 0, -1])

    cache_keys
  end

  defp decode(value), do: :erlang.binary_to_term(value)
  defp encode(value), do: :erlang.term_to_binary(value)

  defp get_cache_expiration_in_seconds(options) do
    options
    |> Keyword.get(:expiration, @default_expiration)
    |> Artemis.Helpers.to_integer()
    |> Kernel./(1_000)
    |> Float.ceil()
    |> Artemis.Helpers.to_integer()
  end
end
