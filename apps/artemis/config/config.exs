use Mix.Config

config :artemis,
  ecto_repos: [Artemis.Repo]

config :artemis, :actions,
  ibm_cloud_iam_access_token: [
    enabled: System.get_env("ARTEMIS_ACTION_IBM_CLOUD_IAM_ACCESS_TOKEN_ENABLED")
  ],
  ibm_cloudant_change_listener: [
    enabled: System.get_env("ARTEMIS_ACTION_IBM_CLOUDANT_CHANGE_LISTENER")
  ],
  ibm_cloudant_migrator: [
    enabled: System.get_env("ARTEMIS_ACTION_IBM_CLOUDANT_MIGRATOR")
  ],
  pager_duty_synchronize_incidents: [
    enabled: System.get_env("ARTEMIS_ACTION_PAGER_DUTY_SYNCHRONIZE_INCIDENTS")
  ],
  pager_duty_synchronize_on_call: [
    enabled: System.get_env("ARTEMIS_ACTION_PAGER_DUTY_SYNCHRONIZE_ON_CALL")
  ],
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

config :artemis, :users,
  root_user: %{
    name: System.get_env("ARTEMIS_ROOT_USER"),
    email: System.get_env("ARTEMIS_ROOT_EMAIL")
  },
  system_user: %{
    name: System.get_env("ARTEMIS_SYSTEM_USER"),
    email: System.get_env("ARTEMIS_SYSTEM_EMAIL")
  }

config :artemis, :ibm_cloud,
  iam_api_key: System.get_env("ARTEMIS_IBM_CLOUD_IAM_API_KEY"),
  iam_api_url: System.get_env("ARTEMIS_IBM_CLOUD_IAM_API_URL")

config :artemis, :ibm_cloudant,
  hosts: [
    [
      name: :shared,
      auth_type: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_AUTH_TYPE"),
      username: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_USERNAME"),
      password: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PASSWORD"),
      hostname: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_HOSTNAME"),
      protocol: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PROTOCOL"),
      global_changes_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_GLOBAL_CHANGES_ENABLED"),
      search_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_ENABLED"),
      search_design_doc: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_DESIGN_DOC"),
      search_index: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_INDEX")
    ]
  ],
  databases: [
    [
      host: :shared,
      name: "jobs",
      schema: Artemis.Job
    ]
  ]

config :artemis, :pager_duty,
  subdomain: System.get_env("ARTEMIS_PAGER_DUTY_SUBDOMAIN"),
  team_ids: System.get_env("ARTEMIS_PAGER_DUTY_TEAM_IDS"),
  token: System.get_env("ARTEMIS_PAGER_DUTY_TOKEN")

config :slugger, separator_char: ?-
config :slugger, replacement_file: "lib/replacements.exs"

import_config "#{Mix.env()}.exs"
