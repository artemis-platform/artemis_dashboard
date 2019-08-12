defmodule Artemis.Customer do
  use Artemis.Schema

  schema "customers" do
    field :name, :string
    field :notes, :string
    field :notes_html, :string

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :name,
      :notes,
      :notes_html
    ]

  def required_fields,
    do: [
      :name
    ]

  def event_log_fields,
    do: [
      :id,
      :name
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> unique_constraint(:name)
  end
end
