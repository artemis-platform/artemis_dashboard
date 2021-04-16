use Mix.Config

config :artemis,
  ecto_repos: [Artemis.Repo]

config :artemis, :actions,
  # NOTE: When adding action entries, also update `config/test.exs`
  repo_delete_all: [
    enabled: System.get_env("ARTEMIS_ACTION_REPO_DELETE_ALL_ENABLED")
  ],
  repo_generate_filler_data: [
    enabled: System.get_env("ARTEMIS_ACTION_REPO_GENERATE_FILLER_DATA_ENABLED")
  ],
  repo_reset_on_interval: [
    enabled: System.get_env("ARTEMIS_ACTION_REPO_RESET_ON_INTERVAL_ENABLED"),
    interval: System.get_env("ARTEMIS_ACTION_REPO_RESET_ON_INTERVAL_HOURS")
  ]

config :artemis, :benchmark, default_log_level: System.get_env("ARTEMIS_BENCHMARK_DEFAULT_LOG_LEVEL")

config :artemis, :users,
  root_user: %{
    name: System.get_env("ARTEMIS_ROOT_USER"),
    email: System.get_env("ARTEMIS_ROOT_EMAIL")
  },
  system_user: %{
    name: System.get_env("ARTEMIS_SYSTEM_USER"),
    email: System.get_env("ARTEMIS_SYSTEM_EMAIL")
  }

config :artemis, :interval_worker,
  default_log_limit: System.get_env("ARTEMIS_INTERVAL_WORKER_DEFAULT_LOG_LIMIT"),
  default_log_level: System.get_env("ARTEMIS_INTERVAL_WORKER_DEFAULT_LOG_LEVEL")

config :config_tuples, distillery: false

import_config "#{Mix.env()}.exs"
