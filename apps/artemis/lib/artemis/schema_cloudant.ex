defmodule Artemis.Schema.Cloudant do
  @moduledoc """
  Adds Cloudant specific schema functions
  """

  @callback filter_fields :: List.t()
  @callback search_fields :: List.t()
  @callback sort_fields :: List.t()

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
        |> Map.get("raw_data")
        |> Artemis.Helpers.deep_merge(data)
        |> Map.delete("raw_data")
      end

      # Config Functions

      def get_cloudant_host() do
        __MODULE__
        |> get_cloudant_database_config()
        |> Keyword.get(:host)
      end

      def get_cloudant_path() do
        __MODULE__
        |> get_cloudant_database_config()
        |> Keyword.get(:name)
      end

      def get_cloudant_search_path() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])
        design_doc = host[:search_design_doc]
        index = host[:search_index]
        base_path = get_cloudant_path()

        "#{base_path}/_design/#{design_doc}/_search/#{index}"
      end

      def get_cloudant_url() do
        database = get_cloudant_database_config(__MODULE__)
        host = get_cloudant_host_config(database[:host])

        "#{host[:hostname]}/#{database[:name]}"
      end

      # Helpers

      defp get_cloudant_database_config(schema) do
        IBMCloudant.Config.get_database_config!(:schema, schema)
      end

      defp get_cloudant_host_config(host_name) do
        IBMCloudant.Config.get_host_config!(:name, host_name)
      end
    end
  end
end
