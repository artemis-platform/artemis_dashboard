defmodule Artemis.EventQuestion do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "event_questions" do
    field :active, :boolean, default: true
    field :order, :integer
    field :title, :string
    field :type, :string

    belongs_to :event_template, Artemis.EventTemplate, on_replace: :delete

    has_one :team, through: [:event_template, :team]

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :active,
      :event_template_id,
      :order,
      :title,
      :type
    ]

  def required_fields,
    do: [
      :event_template_id,
      :title,
      :type
    ]

  def updatable_associations,
    do: [
      event_template: Artemis.EventTemplate
    ]

  def event_log_fields,
    do: [
      :id,
      :title,
      :type
    ]

  def allowed_types,
    do: [
      "text"
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_inclusion(:type, allowed_types())
    |> foreign_key_constraint(:event_template_id)
  end
end
