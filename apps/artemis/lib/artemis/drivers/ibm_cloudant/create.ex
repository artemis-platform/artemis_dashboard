defmodule Artemis.Drivers.IBMCloudant.Create do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates specified IBM Cloudant database including design docs and associated
  indexes and views.
  """

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config, options \\ []) do
    with {:ok, result} <- create_database(host_config, database_config),
         {:ok, _} <- create_search(host_config, database_config, options),
         {:ok, _} <- create_query_indexes(host_config, database_config, options),
         {:ok, _} <- create_custom_views(host_config, database_config, options),
         {:ok, _} <- create_filter_views(host_config, database_config, options) do
      {:ok, result}
    else
      error -> error
    end
  end

  # Helpers

  defp create_database(host_config, database_config) do
    database_name = Keyword.fetch!(database_config, :name)
    host_name = Keyword.fetch!(host_config, :name)

    host_name
    |> create_database_request(database_name)
    |> parse_results()
  end

  defp create_database_request(host_name, database_name) do
    IBMCloudant.Request.call(%{
      host: host_name,
      method: :put,
      path: database_name
    })
  end

  defp parse_results({:error, %{"error" => "file_exists"}}), do: {:ok, "Database already exists"}
  defp parse_results(result), do: result

  defp create_search(host_config, database_config, options) do
    case Keyword.get(options, :create_search, true) do
      true -> IBMCloudant.CreateSearch.call(host_config, database_config)
      false -> {:ok, :skipped}
    end
  end

  defp create_query_indexes(host_config, database_config, options) do
    case Keyword.get(options, :create_query_indexes, true) do
      true -> IBMCloudant.CreateQueryIndexes.call(host_config, database_config)
      false -> {:ok, :skipped}
    end
  end

  defp create_custom_views(host_config, database_config, options) do
    case Keyword.get(options, :create_custom_views, true) do
      true -> IBMCloudant.CreateCustomViews.call(host_config, database_config)
      false -> {:ok, :skipped}
    end
  end

  defp create_filter_views(host_config, database_config, options) do
    case Keyword.get(options, :create_filter_views, true) do
      true -> IBMCloudant.CreateFilterViews.call(host_config, database_config)
      false -> {:ok, :skipped}
    end
  end
end
