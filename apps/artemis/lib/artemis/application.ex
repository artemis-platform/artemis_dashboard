defmodule Artemis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    children = get_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: Artemis.Supervisor)
  end

  defp get_children() do
    required_children = [
      Artemis.Repo,
      Artemis.CacheSupervisor,
      supervisor(Artemis.IntervalSupervisor, [])
    ]

    required_children
    |> maybe_include_redis_cache_connection_pool()
  end

  defp maybe_include_redis_cache_connection_pool(children) do
    case Artemis.RedisCacheConnectionPool.enabled?() do
      true -> children ++ [supervisor(Artemis.RedisCacheConnectionPool, [])]
      false -> children
    end
  end
end
