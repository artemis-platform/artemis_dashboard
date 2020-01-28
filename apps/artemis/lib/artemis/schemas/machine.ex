defmodule Artemis.Machine do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "machines" do
    field :cpu_total, :integer
    field :cpu_used, :integer
    field :hostname, :string
    field :name, :string
    field :ram_total, :integer
    field :ram_used, :integer
    field :slug, :string

    belongs_to :cloud, Artemis.Cloud, on_replace: :nilify
    belongs_to :data_center, Artemis.DataCenter, on_replace: :nilify

    has_one :customer, through: [:cloud, :customer]

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :cloud_id,
      :cpu_total,
      :cpu_used,
      :data_center_id,
      :hostname,
      :name,
      :ram_total,
      :ram_used,
      :slug
    ]

  def required_fields,
    do: [
      :slug
    ]

  def updatable_associations,
    do: [
      cloud: Artemis.Cloud,
      data_center: Artemis.DataCenter
    ]

  def event_log_fields,
    do: [
      :id,
      :name,
      :slug
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> unique_constraint(:slug)
  end
end
