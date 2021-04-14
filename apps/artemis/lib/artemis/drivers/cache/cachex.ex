defmodule Artemis.Drivers.Cache.Cachex do
  import Cachex.Spec

  def get_cache_instance_options(options) do
    [
      expiration:
        expiration(
          default: Keyword.get(options, :expiration, :timer.minutes(5)),
          interval: :timer.seconds(5)
        ),
      limit: Keyword.get(options, :limit, 100),
      stats: true
    ]
  end

  def create_cache_instance(cache_instance_name, options) do
    Cachex.start_link(cache_instance_name, options)
  end

  def get(cache_instance_name, key) do
    Cachex.get!(cache_instance_name, key)
  rescue
    _ -> nil
  end

  def put(cache_instance_name, key, entry, _options \\ []) do
    {:ok, _} = Cachex.put(cache_instance_name, key, entry)
  end

  def put_many(cache_instance_name, entries, _options \\ []) do
    {:ok, _} = Cachex.put_many(cache_instance_name, entries)
  end

  def reset(cache_instance_name) do
    {:ok, _} = Cachex.clear(cache_instance_name)
  end
end
