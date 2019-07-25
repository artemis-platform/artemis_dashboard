defmodule Artemis.Job do
  use Artemis.Schema
  use Artemis.Schema.Cloudant

  @primary_key false
  embedded_schema do
    field :_id, :string
    field :_rev, :string
    field :cmd, :string
    field :first_run, :integer
    field :last_run, :integer
    field :name, :string
    field :raw_data, :map
    field :status, :string
    field :uuid, :string
  end

  # Callbacks

  def updatable_fields,
    do: [
      :_rev,
      :cmd,
      :first_run,
      :last_run,
      :name,
      :raw_data,
      :status,
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
    do: []

  def search_fields,
    do: [
      :_id,
      :cmd,
      :name,
      :status,
      :uuid
    ]

  def sort_fields,
    do: []

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_cloudant_raw_data()
  end
end
