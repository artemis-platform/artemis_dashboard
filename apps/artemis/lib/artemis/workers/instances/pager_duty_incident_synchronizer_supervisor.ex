defmodule Artemis.Worker.PagerDutyIncidentSynchronizerSupervisor do
  use Supervisor

  @moduledoc """
  Starts and supervises synchronizers for PagerDuty incidents for each team
  defined in the config.

  ## Children

  Supervises a child process for each database defined in the config file
  under the `:artemis, :ibm_cloudant, databases: []` section.

  Dynamically names each process using the generic listener.

  For example, given the config:

    config :artemis, :pager_duty,
      teams: [
        [
          id: System.get_env("ARTEMIS_PAGER_DUTY_TEAM_ID_ONE"),
          name: "Example Team - One",
          slug: :example_team_one
        ],
        [
          id: System.get_env("ARTEMIS_PAGER_DUTY_TEAM_ID_TWO"),
          name: "Example Team - Two",
          slug: :example_team_two
        ]
      ],
      token: System.get_env("ARTEMIS_PAGER_DUTY_TOKEN")

  The supervisor would spawn two children processes to listen for events:

    Artemis.Worker.PagerDutyIncidentSynchronizerInstance.ExampleTeamOne
    Artemis.Worker.PagerDutyIncidentSynchronizerInstance.ExampleTeamTwo

  **Note** the process name is important. It is needed to query information
  about the process:

    Artemis.Worker.PagerDutyIncidentSynchronizerInstance.get_log(
      Artemis.Worker.PagerDutyIncidentSynchronizerInstance.ExampleTeamTwo
    )

  """

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: options[:name] || __MODULE__)
  end

  def init(:ok) do
    children =
      Enum.map(Artemis.Helpers.PagerDuty.get_pager_duty_teams(), fn team ->
        slug = Keyword.get(team, :slug)

        config = [
          id: Keyword.get(team, :id),
          name: get_worker_name(slug),
          slug: slug
        ]

        worker(Artemis.Worker.PagerDutyIncidentSynchronizerInstance, [config], id: slug)
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one]

    supervise(children, options)
  end

  def get_worker_name(slug) do
    short_name = Artemis.Helpers.modulecase(slug)

    String.to_atom("Elixir.Artemis.Worker.PagerDutyIncidentSynchronizerInstance.#{short_name}")
  end
end
