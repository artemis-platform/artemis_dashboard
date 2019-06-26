defmodule Artemis.Drivers.IBMCloudant.Create do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates IBM Cloudant instances and ensures databases and indexes (filter,
  search, sort) exist. Will create any that are missing.
  """

  def call() do
    hosts_config = IBMCloudant.Config.get_hosts_config!()
    databases_config = IBMCloudant.Config.get_databases_config!()
    databases_by_host = Enum.group_by(databases_config, &Keyword.fetch!(&1, :host))
    results = Enum.map(hosts_config, fn host_config ->
      host_name = Keyword.fetch!(host_config, :name)
      existing_databases = get_existing_databases(host_name)
      expected_databases = Map.fetch!(databases_by_host, host_name)
      search_enabled_on_host? = Keyword.fetch!(host_config, :search_enabled)

      Enum.map(expected_databases, fn database ->
        database_name = Keyword.fetch!(database, :name)
        database_schema = Keyword.fetch!(database, :schema)

        # Create Database

        unless Enum.member?(existing_databases, database_name) do
          {:ok, _} = create_database(host_name, database_name)
        end

        # Create Search Index

        if search_enabled_on_host? do
          search_options = [
            design_doc: Keyword.fetch!(host_config, :search_design_doc),
            index: Keyword.fetch!(host_config, :search_index)
          ]

          {:ok, _} = IBMCloudant.SearchIndex.call(database_schema, search_options)
        end

        # TODO Create Filter Indexes

        # TODO Create Sort Indexes

      end)
    end)

    {:ok, results}
  end

  # Helpers

  defp get_existing_databases(host) do
    {:ok, databases} = IBMCloudant.Request.call(%{
      host: host,
      method: :get,
      path: "_all_dbs"
    })

    databases
  end

  defp create_database(host, database_name) do
    IBMCloudant.Request.call(%{
      host: host,
      method: :put,
      path: database_name
    })
  end
end
