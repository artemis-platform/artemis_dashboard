use Mix.Config

config :artemis_notify,
  ecto_repos: [Artemis.Repo],
  generators: [context_app: :artemis],
  namespace: ArtemisNotify,
  release_branch: System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"]) |> elem(0) |> String.trim(),
  release_hash: System.cmd("git", ["rev-parse", "--short", "HEAD"]) |> elem(0) |> String.trim()

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
