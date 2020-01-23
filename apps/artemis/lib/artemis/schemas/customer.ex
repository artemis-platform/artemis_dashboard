defmodule Artemis.Customer do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "customers" do
    field :name, :string
    field :notes, :string
    field :notes_html, :string

    has_many :clouds, Artemis.Cloud, on_delete: :nilify_all
    has_many :data_centers, through: [:clouds, :machines, :data_center]
    has_many :machines, through: [:clouds, :machines]

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
