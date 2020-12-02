use Mix.Config

config :artemis_notify,
  artemis_web_url: System.get_env("ARTEMIS_WEB_HOSTNAME"),
  ecto_repos: [Artemis.Repo],
  generators: [context_app: :artemis],
  namespace: ArtemisNotify,
  release_branch: System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"]) |> elem(0) |> String.trim(),
  release_hash: System.cmd("git", ["rev-parse", "--short", "HEAD"]) |> elem(0) |> String.trim()

config :artemis_notify, :actions,
  # NOTE: When adding action entries, also update `config/test.exs`
  placeholder: [
    enabled: System.get_env("ARTEMIS_NOTIFY_ACTION_PLACEHOLDER_ENABLED")
  ]

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
