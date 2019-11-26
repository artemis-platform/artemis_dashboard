defmodule Artemis.IntervalSupervisor do
  @moduledoc """
  Starts and supervises interval workers.
  """

  use Supervisor

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: options[:name] || __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Artemis.Worker.IBMCloudantChangeSupervisor, []),
      worker(Artemis.Worker.IBMCloudIAMAccessToken, []),
      worker(Artemis.Worker.IBMCloudantMigrator, []),
      supervisor(Artemis.Worker.PagerDutyIncidentSynchronizerSupervisor, []),
      worker(Artemis.Worker.PagerDutyIncidentStatus, []),
      worker(Artemis.Worker.PagerDutyOnCallSynchronizer, []),
      worker(Artemis.Worker.RepoResetOnInterval, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one]

    supervise(children, options)
  end
end
