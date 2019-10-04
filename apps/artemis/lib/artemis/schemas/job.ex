defmodule Artemis.Job do
  use Artemis.Schema
  use Artemis.Schema.Cloudant

  @primary_key false
  embedded_schema do
    field :_id, :string
    field :_rev, :string
    field :cmd, :string
    field :deps, :string
    field :first_run, :integer
    field :instance_uuid, :string
    field :last_run, :integer
    field :name, :string
    field :raw_data, :map
    field :status, :string
    field :task_id, :string
    field :transaction_id, :string
    field :uuid, :string
    field :zzdoc_type, :string
  end

  # Callbacks

  def updatable_fields,
    do: [
      :_rev,
      :cmd,
      :first_run,
      :last_run,
      :instance_uuid,
      :name,
      :raw_data,
      :status,
      :task_id,
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

  def filter_fields,
    do: [
      :instance_uuid,
      :task_id,
      :transaction_id
    ]

  def index_fields,
    do: [
      :cmd,
      :deps,
      :first_run,
      :instance_uuid,
      :last_run,
      :name,
      :status,
      :task_id,
      :transaction_id,
      :uuid,
      :zzdoc_type
    ]

  def search_fields,
    do: [
      :_id,
      :cmd,
      :deps,
      :name,
      :status,
      :task_id,
      :uuid
    ]

  def custom_views,
    do: %{}

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_cloudant_raw_data()
  end
end
