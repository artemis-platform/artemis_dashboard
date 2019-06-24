defmodule Artemis.SharedJob do
  use Artemis.Schema
  use Artemis.Schema.Cloudant

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

  # Callbacks

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

  def search_fields,
    do: [
      :_id,
      :cmd,
      :name,
      :status,
      :uuid
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_cloudant_raw_data()
  end
end
