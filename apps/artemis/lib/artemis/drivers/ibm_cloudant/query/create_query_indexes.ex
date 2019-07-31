defmodule Artemis.Drivers.IBMCloudant.CreateQueryIndexes do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates query indexes

  ## Warning!

  Indexes are expensive to create. Avoid cascading updates by only
  adding new indexes as needed.
  """

  @default_design_doc "query-indexes"

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config) do
    database_schema = Keyword.fetch!(database_config, :schema)

    get_or_create_query_indexes(host_config, database_schema)
  end

  # Helpers

  defp get_or_create_query_indexes(host_config, database_schema) do
    cloudant_host = database_schema.get_cloudant_host()
    cloudant_path = database_schema.get_cloudant_path()
    design_doc_name = get_design_doc_name(host_config)
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

  defp get_design_doc_name(host_config) do
    Keyword.get(host_config, :index_design_doc, @default_design_doc)
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

    case Keyword.get(host_config, :query_index_include_partion_param) do
      "true" -> Map.put(params, :partitioned, false)
      _ -> params
    end
  end
end
