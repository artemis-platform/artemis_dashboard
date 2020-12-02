defmodule Artemis.MixProject do
  use Mix.Project

  def project do
    [
      app: :artemis,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Artemis.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib", "test/support"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:assoc, "~> 0.1"},
      {:config_tuples, "~> 0.4.2"},
      {:cachex, "~> 3.1"},
      {:httpoison, "~> 1.5"},
      {:slugger, "~> 0.3"},
      {:hashids, "~> 2.0"},
      {:timex, "~> 3.6"},
      {:castore, "~> 0.1.0"},
      {:mint, "~> 0.4.0"},
      {:earmark, "~> 1.3"},
      {:html_sanitize_ex, "~> 1.3"},
      {:cocktail, "~> 0.8"},
      {:progress_bar, "> 0.0.0"},
      {:ex_machina, "~> 2.2"},
      {:faker, "~> 0.11"},
      {:licensir, "~> 0.4", only: :dev, runtime: false},
      {:artemis_pubsub, in_umbrella: true}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
