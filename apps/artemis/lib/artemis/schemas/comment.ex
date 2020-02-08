defmodule Artemis.Comment do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "comments" do
    field :body, :string
    field :body_html, :string
    field :resource_id, :string
    field :resource_type, :string
    field :title, :string
    field :topic, :string

    belongs_to :user, Artemis.User

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :body,
      :body_html,
      :resource_id,
      :resource_type,
      :title,
      :topic,
      :user_id
    ]

  def required_fields,
    do: [
      :body,
      :body_html,
      :resource_id,
      :resource_type,
      :title,
      :topic,
      :user_id
    ]

  def event_log_fields,
    do: [
      :id,
      :resource_id,
      :resource_type,
      :title,
      :topic,
      :user_id
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
  end
end
