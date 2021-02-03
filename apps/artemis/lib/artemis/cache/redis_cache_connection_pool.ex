defmodule Artemis.RedisCacheConnectionPool do
  use Supervisor

  @moduledoc """
  Manage a pool of connections to a redis cache instance.

  Exposes the `command` function which can be used to choose a random
  connection from the pool to communicate with redis.
  """

  @prefix "redis_cache"
  @default_max_timeout :timer.seconds(5)
  @default_retry_interval 25
  @default_retry_limit 1_200

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: options[:name] || __MODULE__)
  end

  @impl true
  def init(:ok) do
    children =
      for index <- 0..(get_pool_size() - 1) do
        child_options = get_child_options(index)

        Supervisor.child_spec({Redix, child_options}, id: {Redix, index})
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one]

    Supervisor.init(children, options)
  end

  @doc """
  Send a command to Redis using a random connection from the pool
  """
  def command(value, options \\ []) do
    call_with_max_timeout(
      fn ->
        connection = get_connection(options)

        case Redix.command(connection, value) do
          {:error, %Redix.ConnectionError{reason: :closed}} ->
            restart_pool_worker(connection)
            command(value, options)

          result ->
            result
        end
      end,
      options
    )
  end

  @doc """
  Send a pipeline to Redis using a random connection from the pool
  """
  def pipeline(values, options \\ []) do
    call_with_max_timeout(
      fn ->
        connection = get_connection(options)

        case Redix.pipeline(connection, values) do
          {:error, %Redix.ConnectionError{reason: :closed}} ->
            restart_pool_worker(connection)
            pipeline(values, options)

          result ->
            result
        end
      end,
      options
    )
  end

  @doc """
  Return whether the redis cache connection pool is enabled in the config
  """
  def enabled? do
    redis_enabled?() && redis_pool_enabled?()
  end

  defp redis_enabled? do
    Artemis.Helpers.AppConfig.enabled?(:artemis, :cache, :redis)
  end

  defp redis_pool_enabled? do
    config = Artemis.Helpers.AppConfig.fetch!(:artemis, :cache, :redis)
    pool_enabled = Keyword.get(config, :pool_enabled)

    Artemis.Helpers.AppConfig.enabled?(pool_enabled)
  end

  # Helpers

  defp random_index() do
    0
    |> Range.new(get_pool_size())
    |> Enum.random()
  end

  defp get_pool_size() do
    redis_config = Artemis.Helpers.AppConfig.fetch!(:artemis, :cache, :redis)
    pool_size = Keyword.fetch!(redis_config, :pool_size)

    case Artemis.Helpers.present?(pool_size) do
      true -> Artemis.Helpers.to_integer(pool_size)
      false -> 0
    end
  end

  defp get_child_options(index) do
    Keyword.put(get_connection_options(), :name, :"#{@prefix}_#{index}")
  end

  defp get_connection_options() do
    config = Artemis.Helpers.AppConfig.fetch!(:artemis, :cache, :redis)

    required_options = [
      database: get_config(config, :database_number),
      host: get_config(config, :host),
      password: get_config(config, :password),
      port: get_config(config, :port),
      ssl: get_config(config, :ssl)
    ]

    maybe_add_ssl_options(required_options, config)
  end

  defp get_config(config, :database_number) do
    value = Keyword.get(config, :database_number)

    case Artemis.Helpers.present?(value) do
      true -> Artemis.Helpers.to_integer(value)
      false -> 0
    end
  end

  defp get_config(config, :port) do
    value = Keyword.get(config, :port)

    case Artemis.Helpers.present?(value) do
      true -> Artemis.Helpers.to_integer(value)
      false -> nil
    end
  end

  defp get_config(config, :ssl) do
    value = Keyword.get(config, :ssl)

    case Artemis.Helpers.present?(value) do
      true ->
        value
        |> String.downcase()
        |> String.equivalent?("true")

      false ->
        false
    end
  end

  defp get_config(config, key) do
    value = Keyword.get(config, key)

    case Artemis.Helpers.present?(value) do
      true -> value
      false -> nil
    end
  end

  defp maybe_add_ssl_options(options, _config) do
    case Keyword.get(options, :ssl, false) do
      true ->
        ssl_options = [
          socket_opts: [
            verify: :verify_none,
            depth: 3,
            customize_hostname_check: [
              match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
            ]
          ]
        ]

        options ++ ssl_options

      _ ->
        options
    end
  end

  defp get_connection(options) do
    case redis_pool_enabled?() do
      true -> get_pool_connection(options)
      false -> create_new_connection(options)
    end
  end

  defp get_pool_connection(options, iterations \\ 0) do
    name = :"#{@prefix}_#{random_index()}"
    pid = Process.whereis(name)
    retry_interval = Keyword.get(options, :retry_interval, @default_retry_interval)
    retry_limit = Keyword.get(options, :retry_limit, @default_retry_limit)
    under_retry_limit? = iterations < retry_limit

    cond do
      pid && Process.alive?(pid) -> name
      under_retry_limit? -> :timer.sleep(retry_interval) && get_pool_connection(options, iterations + 1)
      true -> Artemis.Helpers.error("Redis cache connection pool retry limit reached")
    end
  end

  defp create_new_connection(_options) do
    connection_options = get_connection_options()

    {:ok, conn} = Redix.start_link(connection_options)

    conn
  end

  defp call_with_max_timeout(callback, options) do
    task = Task.async(callback)
    timeout = Keyword.get(options, :timeout, @default_max_timeout)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} -> result
      _ -> Artemis.Helpers.error("Redis cache connection reached max timeout of #{timeout}ms")
    end
  end

  defp restart_pool_worker(name) when is_atom(name) do
    name
    |> Process.whereis()
    |> restart_pool_worker()
  end

  defp restart_pool_worker(pid), do: Process.exit(pid, :normal)
end
