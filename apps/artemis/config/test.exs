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

config :artemis, Artemis.Repo,
  username: System.get_env("ARTEMIS_POSTGRES_USER"),
  password: System.get_env("ARTEMIS_POSTGRES_PASS"),
  database: System.get_env("ARTEMIS_POSTGRES_DB") <> "_test",
  hostname: System.get_env("ARTEMIS_POSTGRES_HOST"),
  pool: Ecto.Adapters.SQL.Sandbox

config :artemis, :ibm_cloudant,
  prepend_database_names_with: "test_"
