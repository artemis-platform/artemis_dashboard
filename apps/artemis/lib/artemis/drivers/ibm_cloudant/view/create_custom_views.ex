defmodule Artemis.Drivers.IBMCloudant.CreateCustomViews do
  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Creates custom views

  ## Warning!

  Views are expensive to create. To avoid cascading updates, every
  attempt is made to determine if the keys already exist.

  Do not "optimize" code by switching bitstring keys to atoms, etc, without
  a full understanding of the ramifications.
  """

  def call(schema) do
    database_config = IBMCloudant.Config.get_database_config_by!(schema: schema)
    host_config = IBMCloudant.Config.get_host_config_by!(name: database_config[:host])

    call(host_config, database_config)
  end

  def call(host_config, database_config) do
    database_schema = Keyword.fetch!(database_config, :schema)

    get_or_create_custom_views(host_config, database_schema)
  end

  # Helpers

  defp get_or_create_custom_views(_host_config, database_schema) do
    cloudant_host = database_schema.get_cloudant_host()
    cloudant_path = database_schema.get_cloudant_path()
    design_doc_name = database_schema.get_cloudant_view_custom_design_doc_name()

    design_doc_body = %{
      options: %{
        partitioned: false
      }
    }

    {:ok, design_doc} =
      IBMCloudant.GetOrCreateDesignDocument.call(
        cloudant_host,
        cloudant_path,
        design_doc_name,
        design_doc_body
      )

    custom_views = database_schema.custom_views()
    existing_views = Map.get(design_doc, "views", %{})
    updated_design_doc = Map.put(design_doc, "views", custom_views)

    case existing_views == custom_views do
      true -> {:ok, "Custom views already exist"}
      false -> IBMCloudant.CreateDesignDocument.call(cloudant_host, cloudant_path, design_doc_name, updated_design_doc)
    end
  end
end
