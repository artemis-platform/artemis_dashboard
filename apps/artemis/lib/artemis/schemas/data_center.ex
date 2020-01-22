defmodule Artemis.DataCenter do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "data_centers" do
    field :country, :string
    field :latitude, :string
    field :longitude, :string
    field :name, :string
    field :slug, :string

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :country,
      :latitude,
      :longitude,
      :name,
      :slug
    ]

  def required_fields,
    do: [
      :name,
      :slug
    ]

  def event_log_fields,
    do: [
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
