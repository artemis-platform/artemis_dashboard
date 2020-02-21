defmodule Artemis.Team do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "teams" do
    field :description, :string
    field :name, :string

    field :user_count, :integer, virtual: true

    has_many :event_templates, Artemis.EventTemplate, on_delete: :delete_all, on_replace: :delete
    has_many :event_questions, through: [:event_templates, :event_questions]
    has_many :user_teams, Artemis.UserTeam, on_delete: :delete_all, on_replace: :delete
    has_many :users, through: [:user_teams, :user]

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :description,
      :name
    ]

  def required_fields,
    do: [
      :name
    ]

  def updatable_associations,
    do: [
      user_teams: Artemis.UserTeam
    ]

  def event_log_fields,
    do: [
      :id
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
  end
end
