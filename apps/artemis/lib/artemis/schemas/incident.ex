defmodule Artemis.Incident do
  use Artemis.Schema
  use Assoc.Schema, repo: Artemis.Repo

  schema "incidents" do
    field :acknowledged_at, :utc_datetime
    field :acknowledged_by, :string
    field :description, :string
    field :meta, :map
    field :resolved_at, :utc_datetime
    field :resolved_by, :string
    field :severity, :string
    field :source, :string
    field :source_uid, :string
    field :status, :string
    field :time_to_acknowledge, :integer
    field :time_to_resolve, :integer
    field :title, :string
    field :triggered_at, :utc_datetime
    field :triggered_by, :string

    many_to_many :comments, Artemis.Comment, join_through: "comments_incidents", on_delete: :delete_all, on_replace: :delete
    many_to_many :tags, Artemis.Tag, join_through: "tags_incidents", on_delete: :delete_all, on_replace: :delete

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :acknowledged_at,
    :acknowledged_by,
    :description,
    :meta,
    :resolved_at,
    :resolved_by,
    :severity,
    :source,
    :source_uid,
    :status,
    :title,
    :triggered_at,
    :triggered_by
  ]

  def required_fields, do: [
    :severity,
    :source,
    :status,
    :title
  ]

  def updatable_associations, do: [
    tags: Artemis.Tag
  ]

  def event_log_fields, do: [
    :id,
    :severity,
    :source,
    :status,
    :title
  ]

  def allowed_statuses, do: [
    "triggered",
    "acknowledged",
    "resolved"
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_inclusion(:status, allowed_statuses())
    |> unique_constraint(:incidents_source_uid_unique_index)
  end
end
