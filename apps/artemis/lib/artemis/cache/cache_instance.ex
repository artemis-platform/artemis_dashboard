defmodule Artemis.CacheInstance do
  use GenServer, restart: :transient

  require Logger

  alias Artemis.CacheEvent

  defmodule CacheEntry do
    defstruct [:data, :inserted_at, :key]
  end

  @moduledoc """
  A thin wrapper around a cache instance. Supports multiple cache drivers.

  Encapsulates all the application specific logic like subscribing to events,
  reseting cache values automatically.

  ## GenServer Configuration

  By default the `restart` value of a GenServer child is `:permanent`. This is
  perfect for the common scenario where child processes should always be
  restarted.

  In the case of a cache instance, each is created dynamically only when
  needed. There may be cases where a cache instance is no longer needed, and
  should be shut down. To enable this, the CacheInstance uses the `:transient`
  value. This ensures the cache is only restarted if it was shutdown abnormally.

  For more information on see the [Supervisor Documentation](https://hexdocs.pm/elixir/1.8.2/Supervisor.html#module-restart-values-restart).

  ## Preventing Cache Stampeding

  When the cache is empty, the first call to `fetch()` will execute the
  `getter` function and insert the result into the cache.

  While the initial `getter` function is being evaluated but not yet completed,
  any additional calls to `fetch` will also see an empty cache and start
  executing the `getter` function. While inefficient, this duplication is
  especially problematic if the getter function is expensive or takes a long time
  to execute.

  The GenServer can be used as a simple queuing mechanism to prevent this
  "thundering herd" scenario and ensure the `getter` function is only executed
  once.

  Since all GenServer callbacks are blocking, any additional calls to the
  cache that are received while the `getter` function is being executed will be
  queued until after the initial call completes.

  With the `getter` execution completed and the value stored in the cached, all
  subsequent calls in the queue can read directly from the cache.

  Since the cache can support many different values under different keys, it's
  important to note the `fetch` function will never queue requests for keys
  that are already present in the cache. Only requests for keys that are
  currently empty will be queued.
  """

  @default_cache_options [
    expiration: :timer.minutes(5),
    limit: 100
  ]

  @fetch_timeout :timer.minutes(5)

  # Server Callbacks

  def start_link(options) do
    module = Keyword.fetch!(options, :module)

    initial_state = %{
      cache_instance_name: get_cache_instance_name(module),
      cache_driver: select_cache_driver(Keyword.get(options, :cache_driver)),
      cache_options: Keyword.get(options, :cache_options, @default_cache_options),
      cache_server_name: get_cache_server_name(module),
      cache_reset_on_cloudant_changes: Keyword.get(options, :cache_reset_on_cloudant_changes, []),
      cache_reset_on_events: Keyword.get(options, :cache_reset_on_events, []),
      module: module
    }

    GenServer.start_link(__MODULE__, initial_state, name: initial_state.cache_server_name)
  end

  # Server Functions

  @doc """
  Detect if the cache instance GenServer has been started
  """
  def started?(module) do
    name = get_cache_server_name(module)

    cond do
      Process.whereis(name) -> true
      :global.whereis_name(name) != :undefined -> true
      true -> false
    end
  end

  @doc """
  Fetch the key from the cache instance. If it exists, return the value.
  If it does not, evaluate the `getter` function and cache the result.

  If the `getter` function returns a `{:error, _}` tuple, it will not
  be stored in the cache.
  """
  def fetch(module, key, getter) do
    cache_instance_name = get_cache_instance_name(module)
    cache_driver = get_cache_driver(module)

    case get_from_cache(cache_driver, cache_instance_name, key) do
      nil ->
        Logger.debug("#{cache_instance_name}: cache miss")

        GenServer.call(get_cache_server_name(module), {:fetch, key, getter}, @fetch_timeout)

      value ->
        Logger.debug("#{cache_instance_name}: cache hit")

        value
    end
  end

  @doc """
  Gets the key from the cache instance. If it does not exist, returns `nil`.
  """
  def get(module, key) do
    cache_instance_name = get_cache_instance_name(module)
    cache_driver = get_cache_driver(module)

    get_from_cache(cache_driver, cache_instance_name, key)
  end

  @doc """
  Puts value into the cache, unless it is an error tuple. If it is a function, evaluate it
  """
  def put(module, key, value), do: put_in_cache(module, key, value, get_cache_driver(module), get_cache_options(module))

  @doc """
  Puts many values into the cache
  """
  def put_many(module, entries),
    do: put_many_in_cache(module, entries, get_cache_driver(module), get_cache_options(module))

  def get_cache_server_name(module), do: String.to_atom("#{module}.CacheServer")

  def get_cache_instance_name(module), do: String.to_atom("#{module}.CacheInstance")

  def get_cache_driver(module), do: GenServer.call(get_cache_server_name(module), :cache_driver, @fetch_timeout)

  def get_cache_options(module), do: GenServer.call(get_cache_server_name(module), :cache_options, @fetch_timeout)

  def get_name(module), do: get_cache_server_name(module)

  def default_cache_options, do: @default_cache_options

  @doc """
  Determines if a cache server has been created for the given module
  """
  def exists?(module), do: Enum.member?(Process.registered(), get_cache_server_name(module))

  @doc """
  Clear all cache data
  """
  def reset(module) do
    GenServer.call(get_cache_server_name(module), :reset)
  end

  @doc """
  Stop the cache GenServer and the linked Cache Instance process
  """
  def stop(module) do
    GenServer.stop(get_cache_server_name(module))

    :ok = CacheEvent.broadcast("cache:stopped", module)
  end

  @doc """
  Return the cache driver based on the instance or app config
  """
  def select_cache_driver(cache_instance_cache_driver_config) do
    cache_instance_cache_driver_config
    |> get_cache_driver_config()
    |> get_cache_driver_from_config()
  end

  defp get_cache_driver_config(cache_instance_cache_driver_config) do
    cache_instance_cache_driver_config
    |> get_cache_driver_config_value()
    |> Artemis.Helpers.to_string()
    |> String.downcase()
  end

  defp get_cache_driver_config_value(cache_instance_cache_driver_config) do
    case Artemis.Helpers.present?(cache_instance_cache_driver_config) do
      true -> cache_instance_cache_driver_config
      false -> get_global_cache_driver_config()
    end
  end

  defp get_global_cache_driver_config() do
    :artemis
    |> Artemis.Helpers.AppConfig.fetch!(:cache, :driver)
    |> Kernel.||("")
    |> String.downcase()
  end

  defp get_cache_driver_from_config(config) do
    case Artemis.Helpers.to_string(config) do
      "postgres" -> Artemis.Drivers.Cache.Postgres
      "redis" -> Artemis.Drivers.Cache.Redis
      _ -> Artemis.Drivers.Cache.Cachex
    end
  end

  # Instance Callbacks

  @impl true
  def init(initial_state) do
    cache_options = initial_state.cache_driver.get_cache_instance_options(initial_state.cache_options)

    {:ok, cache_instance_pid} =
      initial_state.cache_driver.create_cache_instance(initial_state.cache_instance_name, cache_options)

    state =
      initial_state
      |> Map.put(:cache_instance_pid, cache_instance_pid)
      |> Map.put(:cache_options, cache_options)

    subscribe_to_cloudant_changes(initial_state)
    subscribe_to_events(initial_state)

    :ok = CacheEvent.broadcast("cache:started", initial_state.module)

    {:ok, state}
  end

  @impl true
  def handle_call(:cache_driver, _from, state) do
    {:reply, state.cache_driver, state}
  end

  def handle_call(:cache_options, _from, state) do
    {:reply, state.cache_options, state}
  end

  def handle_call({:fetch, key, getter}, _from, state) do
    entry = fetch_from_cache(state.module, key, getter, state.cache_driver, state.cache_options)

    {:reply, entry, state}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, reset_cache(state)}
  end

  @impl true
  def handle_info(%{event: _event, payload: %{type: "cloudant-change"} = payload}, state) do
    process_cloudant_event(payload, state)
  end

  def handle_info(%{event: event, payload: payload}, state), do: process_event(event, payload, state)

  # Cache Instance Helpers

  defp get_from_cache(cache_driver, cache_instance_name, key) do
    cache_driver.get(cache_instance_name, key)
  end

  defp put_in_cache(_module, _key, {:error, message}, _cache_driver, _cache_options),
    do: %CacheEntry{data: {:error, message}}

  defp put_in_cache(module, key, value, cache_driver, cache_options) do
    cache_instance_name = get_cache_instance_name(module)
    inserted_at = DateTime.utc_now() |> DateTime.to_unix()

    entry = %CacheEntry{
      data: value,
      inserted_at: inserted_at,
      key: key
    }

    cache_driver.put(cache_instance_name, key, entry, cache_options)

    entry
  end

  defp put_many_in_cache(module, entries, cache_driver, cache_options) do
    cache_instance_name = get_cache_instance_name(module)
    inserted_at = DateTime.utc_now() |> DateTime.to_unix()

    cache_entries =
      Enum.map(entries, fn {key, value} ->
        entry = %CacheEntry{
          data: value,
          inserted_at: inserted_at,
          key: key
        }

        {key, entry}
      end)

    cache_driver.put_many(cache_instance_name, cache_entries, cache_options)

    cache_entries
  end

  defp fetch_from_cache(module, key, getter, cache_driver, cache_options) do
    cache_instance_name = get_cache_instance_name(module)

    case get_from_cache(cache_driver, cache_instance_name, key) do
      nil ->
        Logger.debug("#{cache_instance_name}: fetch - updating cache")

        put_in_cache(module, key, getter.(), cache_driver, cache_options)

      value ->
        Logger.debug("#{cache_instance_name}: fetch - cache hit")

        value
    end
  end

  # Helpers - Events

  defp subscribe_to_cloudant_changes(%{cache_reset_on_cloudant_changes: changes}) when length(changes) > 0 do
    Enum.map(changes, fn change ->
      schema = Map.get(change, :schema)
      topic = Artemis.CloudantChange.topic(schema)

      :ok = ArtemisPubSub.subscribe(topic)
    end)
  end

  defp subscribe_to_cloudant_changes(_), do: :skipped

  defp subscribe_to_events(%{cache_reset_on_events: events}) when length(events) > 0 do
    topic = Artemis.Event.get_broadcast_topic()

    :ok = ArtemisPubSub.subscribe(topic)
  end

  defp subscribe_to_events(_state), do: :skipped

  defp process_cloudant_event(payload, state) do
    case matches_any?(state.cache_reset_on_cloudant_changes, payload) do
      true -> {:noreply, reset_cache(state, payload)}
      false -> {:noreply, state}
    end
  end

  defp matches_any?(items, target) do
    Enum.any?(items, &Artemis.Helpers.subset?(&1, target))
  end

  defp process_event(event, payload, state) do
    case Enum.member?(state.cache_reset_on_events, event) do
      true -> {:noreply, reset_cache(state, payload)}
      false -> {:noreply, state}
    end
  end

  # Helpers

  defp reset_cache(state, event \\ %{}) do
    cache_instance_name = get_cache_instance_name(state.module)

    state.cache_driver.reset(cache_instance_name)

    :ok = CacheEvent.broadcast("cache:reset", state.module, event)

    Logger.debug("#{state.cache_instance_name}: Cache reset by event #{event}")

    state
  end
end
