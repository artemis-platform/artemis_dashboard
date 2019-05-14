use Mix.Config

config :artemis_log,
  ecto_repos: [ArtemisLog.Repo],
  subscribe_to_events: true,
  subscribe_to_http_requests: true

import_config "#{Mix.env()}.exs"
