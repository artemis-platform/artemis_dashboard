defmodule Artemis.Machine do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "machines" do
    field :hostname, :string
    field :name, :string
    field :slug, :string

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :hostname,
      :name,
      :slug
    ]

  def required_fields,
    do: [
      :slug
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
