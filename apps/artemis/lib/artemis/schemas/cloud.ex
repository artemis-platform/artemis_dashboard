defmodule Artemis.Cloud do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "clouds" do
    field :name, :string
    field :slug, :string

    belongs_to :customer, Artemis.Customer, on_replace: :nilify

    has_many :machines, Artemis.Machine, on_delete: :nilify_all
    has_many :data_centers, through: [:machines, :data_center]

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :customer_id,
      :name,
      :slug
    ]

  def required_fields,
    do: [
      :slug
    ]

  def updatable_associations,
    do: [
      customer: Artemis.Customer
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
