defmodule Artemis.UserTeam do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "user_teams" do
    field :type, :string

    belongs_to :created_by, Artemis.User, foreign_key: :created_by_id
    belongs_to :team, Artemis.Team, on_replace: :delete
    belongs_to :user, Artemis.User, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :type,
      :created_by_id,
      :team_id,
      :user_id
    ]

  def required_fields,
    do: [
      :created_by_id,
      :team_id,
      :user_id
    ]

  def event_log_fields,
    do: [
      :type,
      :created_by_id,
      :team_id,
      :user_id
    ]

  def allowed_types,
    do: [
      "admin",
      "member",
      "viewer"
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_inclusion(:type, allowed_types())
    |> foreign_key_constraint(:created_by)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:user_id)
  end
end
