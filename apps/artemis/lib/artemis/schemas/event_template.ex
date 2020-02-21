defmodule Artemis.EventTemplate do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "event_templates" do
    field :active, :boolean, default: true
    field :title, :string

    belongs_to :team, Artemis.Team, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :active,
      :team_id,
      :title
    ]

  def required_fields,
    do: [
      :team_id,
      :title
    ]

  def updatable_associations,
    do: [
      team: Artemis.Team
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
    |> foreign_key_constraint(:team_id)
  end
end
