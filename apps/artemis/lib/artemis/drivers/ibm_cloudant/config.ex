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
          protocol: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PROTOCOL"),
          create_change_databases: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_CREATE_CHANGE_DATABASES"),
          query_index_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_QUERY_INDEX_ENABLED"),
          query_index_include_partition_param: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_QUERY_INDEX_INCLUDE_PARTITION_PARAM"),
          search_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_ENABLED"),
          search_design_doc_base: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_DESIGN_DOC_BASE"),
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

  def get_database_config_by!(options) when is_list(options) and length(options) == 1 do
    {key, value} = Enum.at(options, 0)

    get_database_config_by!(key, value)
  end

  def get_database_config_by!(key, value) do
    get_config()
    |> Keyword.fetch!(:databases)
    |> Enum.find(&(Keyword.fetch!(&1, key) == value))
  end

  def get_databases_config!() do
    get_config()
    |> Keyword.fetch!(:databases)
  end

  def get_host_config_by!(options) when is_list(options) and length(options) == 1 do
    {key, value} = Enum.at(options, 0)

    get_host_config_by!(key, value)
  end

  def get_host_config_by!(key, value) do
    get_config()
    |> Keyword.fetch!(:hosts)
    |> Enum.find(&(Keyword.fetch!(&1, key) == value))
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

    updated =
      Enum.map(databases, fn database ->
        name = Keyword.get(database, :name)

        Keyword.put(database, :name, "#{value}#{name}")
      end)

    Keyword.put(config, :databases, updated)
  end
end
