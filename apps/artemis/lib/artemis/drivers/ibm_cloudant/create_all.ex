defmodule Artemis.Drivers.IBMCloudant.CreateAll do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates IBM Cloudant instances and ensures databases and indexes (filter,
  search, sort) exist. Will create any that are missing.

  Is idempotent.
  """

  # See: http://docs.couchdb.org/en/latest/setup/single-node.html
  @change_databases [:_global_changes, :_replicator, :_users]

  def call() do
    hosts_config = IBMCloudant.Config.get_hosts_config!()
    databases_config = IBMCloudant.Config.get_databases_config!()
    databases_by_host = Enum.group_by(databases_config, &Keyword.fetch!(&1, :host))

    results =
      Enum.map(hosts_config, fn host_config ->
        host_name = Keyword.fetch!(host_config, :name)
        existing_databases = get_existing_databases(host_name)
        expected_databases = Map.fetch!(databases_by_host, host_name)

        Enum.map(@change_databases, fn database_name ->
          database_config = [name: database_name]

          {:ok, _} = IBMCloudant.Create.call(host_config, database_config)
        end)

        Enum.map(expected_databases, fn database ->
          database_name = Keyword.fetch!(database, :name)

          unless Enum.member?(existing_databases, database_name) do
            {:ok, _} = IBMCloudant.Create.call(host_config, database)
          end

          {:ok, _} = IBMCloudant.CreateIndexes.call(host_config, database)
        end)
      end)

    {:ok, results}
  end

  # Helpers

  defp get_existing_databases(host) do
    {:ok, databases} =
      IBMCloudant.Request.call(%{
        host: host,
        method: :get,
        path: "_all_dbs"
      })

    databases
  end
end
