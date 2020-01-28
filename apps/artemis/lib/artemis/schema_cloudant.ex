defmodule Artemis.Schema.Cloudant do
  @moduledoc """
  Adds Cloudant specific schema functions
  """

  @callback custom_views :: Map.t()
  @callback filter_fields :: List.t()
  @callback index_fields :: List.t()
  @callback search_fields :: List.t()

  defmacro __using__(_options) do
    quote do
      alias Artemis.Drivers.IBMCloudant

      @behaviour Artemis.Schema.Cloudant

      # Ecto Validators

      def validate_cloudant_raw_data(%{changes: %{raw_data: data}} = changeset) do
        Jason.encode!(data)
        changeset
      rescue
        _ -> add_error(changeset, :raw_data, "invalid json")
      end

      def validate_cloudant_raw_data(changeset), do: changeset

      # Data Transformers

      @doc """
      Creates a new struct from JSON data.

      Stores the original data under the `raw_data` key, ensuring no data is lost
      in the translation to a schema with predefined keys.
      """
      def from_json(data) when is_bitstring(data) do
        data
        |> Jason.decode!()
        |> from_json()
      end

      def from_json(data) do
        params =
          data
          |> Artemis.Helpers.keys_to_atoms()
          |> Map.put(:raw_data, data)

        struct(__MODULE__, params)
      end

      @doc """
      Converts a struct back to JSON compatible map with string keys.

      Merges the struct values with the original data stored under `raw_data` key,
      ensuring no data keys are lost.
      """
      def to_json(struct) do
        data =
          struct
          |> Map.delete(:__struct__)
          |> Artemis.Helpers.keys_to_strings()

        data
        |> Map.get("raw_data", %{})
        |> Artemis.Helpers.deep_merge(data)
        |> Map.delete("raw_data")
      end

      # ID Functions

      def id_without_prefix(record, options \\ []) do
        prefix_end = String.length(__MODULE__.id_prefix())
        length = Keyword.get(options, :length, 8)

        String.slice(record._id || "", prefix_end, length)
      end

      # Config Functions

      def get_cloudant_host() do
        __MODULE__
        |> get_cloudant_database_config()
        |> Keyword.fetch!(:host)
      end

      def get_cloudant_path() do
        __MODULE__
        |> get_cloudant_database_config()
        |> Keyword.fetch!(:name)
      end

      def get_cloudant_query_index_design_doc_name() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc_base = host[:query_index_design_doc_base]

        get_cloudant_design_doc(design_doc_base)
      end

      def get_cloudant_search_design_doc_name() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc_base = host[:search_design_doc_base]

        get_cloudant_design_doc(design_doc_base)
      end

      def get_cloudant_view_custom_design_doc_name() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc_base = host[:view_custom_design_doc_base]

        get_cloudant_design_doc(design_doc_base)
      end

      def get_cloudant_view_filter_design_doc_name() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc_base = host[:view_filter_design_doc_base]

        get_cloudant_design_doc(design_doc_base)
      end

      def get_cloudant_search_path() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc = get_cloudant_search_design_doc_name()
        index = host[:search_index]
        base_path = get_cloudant_path()

        "#{base_path}/_design/#{design_doc}/_search/#{index}"
      end

      def get_cloudant_url() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])

        "#{host[:hostname]}/#{database[:name]}"
      end

      def search_enabled?() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])

        host
        |> Keyword.fetch!(:search_enabled)
        |> String.downcase()
        |> String.equivalent?("true")
      end

      # Common Queries

      @doc """
      Return a list of unique values for a given field.

      Requires a query index to already exist for the field, which is typically
      created by the `def index_fields, do: [:field_name]` entry in the schema file.
      """
      def unique_values_for(field) do
        host = __MODULE__.get_cloudant_host()

        cloudant_path = __MODULE__.get_cloudant_path()
        design_doc = __MODULE__.get_cloudant_query_index_design_doc_name()
        design_doc_path = "#{cloudant_path}/_design/#{design_doc}"

        query_params = [group: true]
        query_string = Plug.Conn.Query.encode(query_params)

        path = "#{design_doc_path}/_view/#{field}?#{query_string}"

        {:ok, data} = IBMCloudant.Request.call(%{host: host, method: :get, path: path})

        data
        |> Map.get("rows")
        |> Enum.map(&hd(Map.get(&1, "key", [])))
      end

      # Helpers

      defp get_cloudant_database_config(schema) do
        IBMCloudant.Config.get_database_config_by!(schema: schema)
      end

      defp get_cloudant_host_config(host_name) do
        IBMCloudant.Config.get_host_config_by!(name: host_name)
      end

      defp get_cloudant_design_doc(base) do
        Artemis.Helpers.dashcase(__MODULE__) <> "-" <> base
      end
    end
  end
end
