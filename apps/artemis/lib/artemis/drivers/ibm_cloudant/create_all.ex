defmodule Artemis.Drivers.IBMCloudant.CreateAll do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates IBM Cloudant instances and ensures databases and indexes (custom,
  filter, search, sort) exist. Will create any that are missing.

  Is idempotent.
  """

  # See: http://docs.couchdb.org/en/latest/setup/single-node.html
  @global_change_databases [:_global_changes, :_replicator, :_users]

  def call() do
    hosts_config = IBMCloudant.Config.get_hosts_config!()
    databases_config = IBMCloudant.Config.get_databases_config!()
    databases_by_host = Enum.group_by(databases_config, &Keyword.fetch!(&1, :host))

    results =
      Enum.map(hosts_config, fn host_config ->
        host_name = Keyword.fetch!(host_config, :name)
        expected_databases = Map.fetch!(databases_by_host, host_name)

        if create_global_change_databases?(host_config) do
          create_global_change_databases(host_config)
        end

        Enum.map(expected_databases, fn database_config ->
          {:ok, _} = IBMCloudant.Create.call(host_config, database_config)
        end)
      end)

    {:ok, results}
  end

  # Helpers

  defp create_global_change_databases?(host_config) do
    host_config
    |> Keyword.fetch!(:create_change_databases)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp create_global_change_databases(host_config) do
    Enum.map(@global_change_databases, fn database_name ->
      database_config = [name: database_name]

      options = [
        create_search: false,
        create_query_indexes: false,
        create_custom_views: false,
        create_filter_views: false
      ]

      {:ok, _} = IBMCloudant.Create.call(host_config, database_config, options)
    end)
  end
end
