defmodule Artemis.UserTeam do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "user_teams" do
    belongs_to :created_by, Artemis.User, foreign_key: :created_by_id
    belongs_to :team, Artemis.Team, on_replace: :delete
    belongs_to :user, Artemis.User, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :created_by_id,
      :team_id,
      :user_id
    ]

  def required_fields, do: []

  def event_log_fields,
    do: [
      :created_by_id,
      :team_id,
      :user_id
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> foreign_key_constraint(:created_by)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:user_id)
  end
end
