use Mix.Config

config :artemis_web,
  ecto_repos: [Artemis.Repo],
  generators: [context_app: :artemis],
  auth_providers: [enabled: System.get_env("ARTEMIS_WEB_ENABLED_AUTH_PROVIDERS")]

config :artemis_web, ArtemisWeb.Endpoint,
  url: [host: System.get_env("ARTEMIS_WEB_HOSTNAME")],
  secret_key_base: System.get_env("ARTEMIS_SECRET_KEY"),
  render_errors: [view: ArtemisWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ArtemisPubSub],
  live_view: [signing_salt: System.get_env("ARTEMIS_WEB_LIVE_VIEW_SECRET_KEY")]

config :artemis_web, ArtemisWeb.Guardian,
  allowed_algos: ["HS512"],
  issuer: "artemis",
  ttl: {18, :hours},
  verify_issuer: true,
  secret_key: System.get_env("ARTEMIS_GUARDIAN_KEY")

config :scrivener_html,
  routes_helper: ArtemisWeb.Router.Helpers,
  view_style: :semantic

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, []},
    system_user: {Ueberauth.Strategy.SystemUser, []}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("ARTEMIS_WEB_GITHUB_CLIENT_ID"),
  client_secret: System.get_env("ARTEMIS_WEB_GITHUB_CLIENT_SECRET")

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, []},
    system_user: {Ueberauth.Strategy.SystemUser, []},
    w3id: {Ueberauth.Strategy.W3ID, []}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("UEBERAUTH_GITHUB_CLIENT_ID"),
  client_secret: System.get_env("UEBERAUTH_GITHUB_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.W3ID.OAuth,
  client_id: System.get_env("UEBERAUTH_W3ID_CLIENT_ID"),
  client_secret: System.get_env("UEBERAUTH_W3ID_CLIENT_SECRET"),
  token_url: System.get_env("UEBERAUTH_W3ID_TOKEN_URL"),
  authorize_url: System.get_env("UEBERAUTH_W3ID_AUTHORIZE_URL")

import_config "#{Mix.env()}.exs"
