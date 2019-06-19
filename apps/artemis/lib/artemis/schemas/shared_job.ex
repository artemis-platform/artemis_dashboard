defmodule Artemis.SharedJob do
  use Artemis.Schema

  @primary_key false
  embedded_schema do
    field :_id, :string
    field :_rev, :string
    field :cmd, :string
    field :deps, :string
    field :estimation, :integer
    field :first_run, :integer
    field :instance_uuid, :string
    field :interval, :integer
    field :last_run, :integer
    field :name, :string
    field :raw_data, :map
    field :status, :string
    field :task_id, :string
    field :timeout, :integer
    field :transaction_id, :string
    field :uuid, :string
    field :zzdoc_type, :string
  end

  # # Callbacks

  def updatable_fields,
    do: [
      :_rev,
      :cmd,
      :deps,
      :estimation,
      :first_run,
      :instance_uuid,
      :interval,
      :last_run,
      :name,
      :raw_data,
      :status,
      :task_id,
      :timeout,
      :transaction_id,
      :uuid,
      :zzdoc_type
    ]

  def required_fields,
    do: []

  def event_log_fields,
    do: [
      :_id,
      :_rev,
      :name,
      :uuid
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_raw_data()
  end

  defp validate_raw_data(%{changes: %{raw_data: data}} = changeset) do
    Jason.encode!(data)
    changeset
  rescue
    _ -> add_error(changeset, :raw_data, "invalid json")
  end

  defp validate_raw_data(changeset), do: changeset

  # Helpers

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

    struct(SharedJob, params)
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
end
