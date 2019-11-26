use Mix.Config

config :artemis,
  ecto_repos: [Artemis.Repo]

config :artemis, :actions,
  # NOTE: When adding action entries, also update `config/test.exs`
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
  iam_api_url: System.get_env("ARTEMIS_IBM_CLOUD_IAM_API_URL"),
  iam_api_keys: [
    ibm_cloud_iam_access_groups: System.get_env("ARTEMIS_IBM_CLOUD_IAM_API_KEY_IBM_CLOUD_IAM_ACCESS_GROUPS"),
    ibm_cloudant_shared: System.get_env("ARTEMIS_IBM_CLOUD_IAM_API_KEY_IBM_CLOUDANT_SHARED")
  ]

config :artemis, :ibm_cloudant,
  hosts: [
    [
      name: :shared,
      ibm_cloud_iam_api_key: :ibm_cloudant_shared,
      auth_type: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_AUTH_TYPE"),
      username: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_USERNAME"),
      password: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PASSWORD"),
      hostname: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_HOSTNAME"),
      protocol: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PROTOCOL"),
      port: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PORT"),
      create_change_databases: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_CREATE_CHANGE_DATABASES"),
      query_index_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_QUERY_INDEX_ENABLED"),
      query_index_design_doc_base: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_QUERY_INDEX_DESIGN_DOC_BASE"),
      query_index_include_partition_param:
        System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_QUERY_INDEX_INCLUDE_PARTITION_PARAM"),
      search_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_ENABLED"),
      search_design_doc_base: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_DESIGN_DOC_BASE"),
      search_index: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_INDEX"),
      view_custom_design_doc_base: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_VIEW_CUSTOM_DESIGN_DOC_BASE"),
      view_filter_design_doc_base: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_VIEW_FILTER_DESIGN_DOC_BASE")
    ]
  ],
  databases: [
    [
      host: :shared,
      name: "jobs",
      schema: Artemis.Job
    ]
  ]

config :artemis, :interval_worker, default_log_limit: System.get_env("ARTEMIS_INTERVAL_WORKER_DEFAULT_LOG_LIMIT")

config :artemis, :pager_duty,
  teams: [
    [
      id: "PTS5TEF",
      name: "vCloud Director",
      slug: :vcloud_director
    ],
    [
      id: "PENNR50",
      name: "vCloud Director - Customer Ops",
      slug: :vcloud_director_customer_ops
    ],
    [
      id: "PHJYRHQ",
      name: "vCloud Director - Platform Ops",
      slug: :vcloud_director_platform_ops
    ]
  ],
  # TODO: remove from config
  # TODO: remove from .env files
  team_ids: System.get_env("ARTEMIS_PAGER_DUTY_TEAM_IDS"),
  token: System.get_env("ARTEMIS_PAGER_DUTY_TOKEN")

config :slugger, separator_char: ?-
config :slugger, replacement_file: "lib/replacements.exs"

import_config "#{Mix.env()}.exs"
