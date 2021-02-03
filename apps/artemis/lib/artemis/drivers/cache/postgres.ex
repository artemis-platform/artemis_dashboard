defmodule Artemis.Drivers.Cache.Postgres do
  @moduledoc """
  Driver for Caching in PostgreSQL, backed by the Key Value schema.

  ## Implementation

  Unlike other drivers that have a unique cache storage per cache instance,
  PostgreSQL uses a single database table. It prevents collisions by prefixing
  cache keys with the cache instance name, as defined in `get_cache_key/2`
  function.

  A separate PostgreSQL entry stores a list of keys for each cache entry using
  `store_cache_instance_cache_key/3`. These are used for operations like reset,
  allowing a "cache instance" to be reset without impacting other entries
  inside the same PostgreSQL database table.
  """

  @default_expiration :timer.minutes(5)

  def get_cache_instance_options(options) do
    [
      expiration: Keyword.get(options, :expiration, @default_expiration),
      limit: Keyword.get(options, :limit, 100)
    ]
  end

  def create_cache_instance(_cache_instance_name, _options) do
    {:ok, :fake_pid_since_using_postgres}
  end

  # TODO
  # recompile && Artemis.Drivers.Cache.Postgres.put("laskey-test", "hello", "world")
  # recompile && Artemis.Drivers.Cache.Postgres.get(Artemis.GetSystemUser.CacheInstance, [])

  # TODO: how to handle expired records? Can cause key has already been taken errors

  def get(cache_instance_name, key) do
    user = Artemis.GetSystemUser.call!()
    cache_key = get_cache_key(cache_instance_name, key)

    params = %{
      filters: %{
        expire_at_lte: Timex.now(),
        key: cache_key
      },
      order_by: "-updated_at"
    }

    case Artemis.ListKeyValues.call(params, user) do
      nil -> nil
      key_values -> get_cache_entry(key_values)
    end
  end

  def put(cache_instance_name, key, entry, options \\ []) do
    user = Artemis.GetSystemUser.call!()

    cache_key = get_cache_key(cache_instance_name, key)
    cache_expiration = get_cache_expiration_time(options)
    cache_value = entry

    params = %{
      key: cache_key,
      value: cache_value,
      expire_at: cache_expiration
    }

    {:ok, key_value} = Artemis.CreateOrUpdateKeyValue.call(params, user)

    {:ok, _} = store_cache_instance_cache_key(cache_instance_name, key_value, user)

    get_cache_entry(key_value)
  end

  @doc """
  Remove all entries for cache instance
  """
  def reset(cache_instance_name) do
    user = Artemis.GetSystemUser.call!()
    cache_instance_cache_keys = get_cache_instance_cache_keys(cache_instance_name, user)

    case length(cache_instance_cache_keys) do
      0 ->
        {:ok, 0}

      size ->
        Enum.map(cache_instance_cache_keys, fn id ->
          Artemis.DeleteKeyValue.call(id, user)
        end)

        Artemis.DeleteKeyValue.call(cache_instance_name, user)

        {:ok, size}
    end
  end

  defp get_cache_key(cache_instance_name, key) do
    {cache_instance_name, key}
  end

  defp store_cache_instance_cache_key(cache_instance_name, record, user) do
    cache_instance_cache_keys = get_cache_instance_cache_keys(cache_instance_name, user)

    params = %{
      key: cache_instance_name,
      value: Enum.uniq([record.id | cache_instance_cache_keys])
    }

    Artemis.CreateOrUpdateKeyValue.call(params, user)
  end

  defp get_cache_instance_cache_keys(cache_instance_name, user) do
    cache_instance_name
    |> Artemis.GetKeyValue.call(user)
    |> Kernel.||(%{})
    |> Map.get(:value)
    |> Kernel.||([])
  end

  defp get_cache_expiration_time(options) do
    ttl = Keyword.get(options, :expiration, @default_expiration)

    Timex.shift(Timex.now(), milliseconds: ttl)
  end

  defp get_cache_entry(records) when is_list(records) do
    records
    |> List.first()
    |> get_cache_entry()
  end

  defp get_cache_entry(key_value_record) do
    key_value_record
    |> Kernel.||(%{})
    |> Map.get(:value)
  end
end
