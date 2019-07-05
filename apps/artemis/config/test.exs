use Mix.Config

# Set the log level
#
# The order from most information to least:
#
#   :debug
#   :info
#   :warn
#
config :logger, level: :info

config :artemis, :actions,
  ibm_cloud_iam_access_token: [enabled: "false"],
  ibm_cloudant_change_listener: [enabled: "false"],
  ibm_cloudant_migrator: [enabled: "false"],
  pager_duty_synchronize_incidents: [enabled: "false"],
  pager_duty_synchronize_on_call: [enabled: "false"],
  repo_delete_all: [enabled: "false"],
  repo_generate_filler_data: [enabled: "false"],
  repo_reset_on_interval: [enabled: "false"]

config :artemis, Artemis.Repo,
  username: System.get_env("ARTEMIS_POSTGRES_USER"),
  password: System.get_env("ARTEMIS_POSTGRES_PASS"),
  database: System.get_env("ARTEMIS_POSTGRES_DB") <> "_test",
  hostname: System.get_env("ARTEMIS_POSTGRES_HOST"),
  pool: Ecto.Adapters.SQL.Sandbox

config :artemis, :ibm_cloudant, prepend_database_names_with: "test_"
