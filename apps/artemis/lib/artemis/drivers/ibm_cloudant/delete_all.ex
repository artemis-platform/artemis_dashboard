defmodule Artemis.Drivers.IBMCloudant.DeleteAll do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Deletes all IBM Cloudant databases on all IBM Cloudant hosts
  """

  def call() do
    hosts_config = IBMCloudant.Config.get_hosts_config!()
    databases_config = IBMCloudant.Config.get_databases_config!()
    databases_by_host = Enum.group_by(databases_config, &Keyword.fetch!(&1, :host))

    results =
      Enum.map(hosts_config, fn host_config ->
        host_name = Keyword.fetch!(host_config, :name)
        existing_databases = get_existing_databases(host_name)
        expected_databases = Map.fetch!(databases_by_host, host_name)

        Enum.map(expected_databases, fn database ->
          database_name = Keyword.fetch!(database, :name)

          if Enum.member?(existing_databases, database_name) do
            {:ok, _} = IBMCloudant.Delete.call(host_config, database)
          end
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
