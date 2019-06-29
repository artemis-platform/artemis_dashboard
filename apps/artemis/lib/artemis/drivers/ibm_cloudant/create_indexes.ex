defmodule Artemis.Drivers.IBMCloudant.CreateIndexes do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates design docs and indexes on specified IBM Cloudant database
  """

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config) do
    database_schema = Keyword.fetch!(database_config, :schema)
    search_enabled_on_host? = Keyword.fetch!(host_config, :search_enabled)

    # Create Search Index

    if search_enabled_on_host? do
      search_options = [
        design_doc: Keyword.fetch!(host_config, :search_design_doc),
        index: Keyword.fetch!(host_config, :search_index)
      ]

      {:ok, _} = IBMCloudant.CreateIndexSearch.call(database_schema, search_options)
    end

    {:ok, true}
  end
end
