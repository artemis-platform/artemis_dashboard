defmodule Artemis.Drivers.IBMCloudant.CreateQueryIndexes do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates query indexes

  ## Warning!

  Indexes are expensive to create. Avoid cascading updates by only
  adding new indexes as needed.
  """

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config) do
    database_schema = Keyword.fetch!(database_config, :schema)

    case query_index_enabled_on_host?(host_config) do
      true -> get_or_create_query_indexes(host_config, database_schema)
      false -> {:ok, "Query indexes not enabled on host"}
    end
  end

  # Helpers

  defp query_index_enabled_on_host?(host_config) do
    host_config
    |> Keyword.fetch!(:query_index_enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp get_or_create_query_indexes(host_config, database_schema) do
    cloudant_host = database_schema.get_cloudant_host()
    cloudant_path = database_schema.get_cloudant_path()
    design_doc_name = database_schema.get_cloudant_query_index_design_doc_name()
    existing_indexes = get_existing_index_names(cloudant_host, cloudant_path)
    index_fields = Enum.map(database_schema.index_fields(), &Atom.to_string(&1))

    Enum.map(index_fields, fn index ->
      case Enum.member?(existing_indexes, index) do
        true -> {:ok, "Index for #{index} already exists"}
        false -> create_index(cloudant_host, cloudant_path, host_config, design_doc_name, index)
      end
    end)

    {:ok, true}
  end

  defp get_existing_index_names(cloudant_host, cloudant_path) do
    {:ok, results} = IBMCloudant.GetIndexes.call(cloudant_host, cloudant_path)

    results
    |> Map.get("indexes", [])
    |> Enum.map(&Map.get(&1, "name"))
  end

  defp create_index(cloudant_host, cloudant_path, host_config, design_doc_name, index) do
    {:ok, _} = create_index_record(cloudant_host, cloudant_path, host_config, design_doc_name, index)
  rescue
    _ in MatchError ->
      :timer.sleep(100)

      create_index_record(cloudant_host, cloudant_path, host_config, design_doc_name, index)
  end

  defp create_index_record(cloudant_host, cloudant_path, host_config, design_doc_name, index) do
    params = get_index_params(host_config, design_doc_name, index)

    IBMCloudant.CreateIndex.call(cloudant_host, cloudant_path, params)
  end

  defp get_index_params(host_config, design_doc_name, field) do
    params = %{
      ddoc: design_doc_name,
      index: %{
        fields: [field]
      },
      name: field,
      type: "json"
    }

    case Keyword.get(host_config, :query_index_include_partition_param) do
      "true" -> Map.put(params, :partitioned, false)
      _ -> params
    end
  end
end
