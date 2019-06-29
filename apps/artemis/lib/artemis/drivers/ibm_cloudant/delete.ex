defmodule Artemis.Drivers.IBMCloudant.Delete do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Deletes specified IBM Cloudant database
  """

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config) do
    database_name = Keyword.fetch!(database_config, :name)
    host_name = Keyword.fetch!(host_config, :name)

    delete_database(host_name, database_name)
  end

  # Helpers

  defp delete_database(host_name, database_name) do
    host_name
    |> delete_request(database_name)
    |> parse_results()
  end

  defp delete_request(host_name, database_name) do
    IBMCloudant.Request.call(%{
      host: host_name,
      method: :delete,
      path: database_name
    })
  end

  defp parse_results({:error, %{"error" => "not_found", "reason" => "Database does not exist."}}), do: {:ok, true}
  defp parse_results(result), do: result
end
