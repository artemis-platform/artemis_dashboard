defmodule Artemis.Job do
  use Artemis.Schema
  use Artemis.Schema.Cloudant

  @primary_key false
  embedded_schema do
    field :_id, :string
    field :_rev, :string
    field :completed_at, :integer
    field :inserted_at, :integer
    field :name, :string
    field :raw_data, :map
    field :started_at, :integer
    field :status, :string
    field :type, :string
    field :updated_at, :integer
    field :uuid, :string
  end

  # Callbacks

  def updatable_fields,
    do: [
      :_rev,
      :completed_at,
      :inserted_at,
      :name,
      :raw_data,
      :started_at,
      :status,
      :type,
      :updated_at,
      :uuid
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
      :name,
      :status,
      :type,
      :uuid
    ]

  def index_fields,
    do: [
      :completed_at,
      :inserted_at,
      :name,
      :started_at,
      :status,
      :type,
      :updated_at,
      :uuid
    ]

  def search_fields,
    do: [
      :_id,
      :name,
      :status,
      :type,
      :uuid
    ]

  def custom_views,
    do: %{}

  def id_prefix,
    do: "job_"

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_cloudant_raw_data()
  end
end
