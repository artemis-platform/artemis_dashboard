defmodule Artemis.Worker.IBMCloudantChangeSupervisor do
  @moduledoc """
  Starts and supervises IBM Cloudant database change listener workers for each
  host defined in the config.

  ## Children

  Supervises a child process for each database defined in the config file
  under the `:artemis, :ibm_cloudant, databases: []` section.

  Dynamically names each process using the generic listener.

  For example, given the config:

    :artemis, :ibm_cloudant,
      hosts: [
        shared: []
      ],
      databases: [
        [
          host: :shared,
          name: "clouds",
          schema: Artemis.Cloud
        ],
        [
          host: :shared,
          name: "jobs",
          schema: Artemis.Job
        ]
      ]

  The supervisor would spawn two children processes to listen for events:

    Artemis.Worker.IBMCloudantChangeListener.Cloud
    Artemis.Worker.IBMCloudantChangeListener.Job

  **Note** the process name is important. It is needed to query information
  about the process:

    Artemis.Worker.IBMCloudantChangeListener.get_log(
      Artemis.Worker.IBMCloudantChangeListener.Job
    )

  """

  use Supervisor

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: options[:name] || __MODULE__)
  end

  def init(:ok) do
    databases =
      :artemis
      |> Application.fetch_env!(:ibm_cloudant)
      |> Keyword.fetch!(:databases)

    children =
      Enum.map(databases, fn database ->
        schema = Keyword.get(database, :schema)

        config = [
          name: get_worker_name(schema),
          schema: schema
        ]

        worker(Artemis.Worker.IBMCloudantChangeListener, [config], id: schema)
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one]

    supervise(children, options)
  end

  # Helpers

  defp get_worker_name(schema) do
    short_name =
      schema
      |> Atom.to_string()
      |> String.split(".")
      |> List.last()

    String.to_atom("#{Artemis.Worker.IBMCloudantChangeListener}.#{short_name}")
  end
end
