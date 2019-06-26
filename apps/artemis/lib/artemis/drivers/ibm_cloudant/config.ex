defmodule Artemis.Drivers.IBMCloudant.Config do
  @moduledoc """
  Cloudant configuration in `config/config.ex` should take the following shape:

    config :artemis, :ibm_cloudant,
      hosts: [
        [
          name: :shared,
          auth_type: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_AUTH_TYPE"),
          username: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_USERNAME"),
          password: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PASSWORD"),
          hostname: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_HOSTNAME"),
          search_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_ENABLED") == "true",
          search_design_doc: "text-search",
          search_index: "text-search-index"
        ]
      ],
      databases: [
        [
          host: :shared,
          name: "jobs",
          schema: Artemis.SharedJob
        ]
      ]

  Where each `databases` value includes a `host: ` value that corresponds with
  a `name: ` field in an entry under the `hosts key.

  NOTICE: each `schema` that uses Cloudant must have a corresponding entry in the
  `databases` section of the config.

  ## Testing

  The optional config key `:prepend_database_names` can be used for testing:

    config :artemis, :ibm_cloudant,
      prepend_database_names_with: "test_"

  When set, the `:name` value for each database entry will be prepended with
  the value. E.g. `jobs` becomes `test_jobs`.
  """

  @config_key :ibm_cloudant

  def get_database_config!(key, value) do
    get_config()
    |> Keyword.fetch!(:databases)
    |> Enum.find(&Keyword.fetch!(&1, key) == value)
  end

  def get_databases_config!() do
    get_config()
    |> Keyword.fetch!(:databases)
  end

  def get_host_config!(key, value) do
    get_config()
    |> Keyword.fetch!(:hosts)
    |> Enum.find(&Keyword.fetch!(&1, key) == value)
  end

  def get_hosts_config!() do
    get_config()
    |> Keyword.fetch!(:hosts)
  end

  # Helpers

  defp get_config() do
    config = Application.fetch_env!(:artemis, @config_key)

    case Keyword.get(config, :prepend_database_names_with) do
      nil -> config
      value -> prepend_database_names(config, value)
    end
  end

  defp prepend_database_names(config, value) do
    databases = Keyword.get(config, :databases)
    updated = Enum.map(databases, fn database ->
      name = Keyword.get(database, :name)

      Keyword.put(database, :name, "#{value}#{name}")
    end)

    Keyword.put(config, :databases, updated)
  end
end
