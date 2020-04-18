defmodule Artemis.EventInstance do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "event_instances" do
    field :description, :string
    field :slug, :string
    field :title, :string

    # TODO: add constraint to ensure unique within event_template

    belongs_to :event_template, Artemis.EventTemplate, on_replace: :delete

    has_one :team, through: [:event_template, :team]

    has_many :event_answers, Artemis.EventAnswer, on_delete: :delete_all, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :description,
      :event_template_id,
      :slug,
      :title
    ]

  def required_fields,
    do: [
      :event_template_id,
      :slug,
      :title
    ]

  def updatable_associations,
    do: [
      event_template: Artemis.EventTemplate
    ]

  def event_log_fields,
    do: [
      :id,
      :title
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> foreign_key_constraint(:event_template_id)
  end
end
