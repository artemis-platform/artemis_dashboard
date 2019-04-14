defmodule Artemis.Comment do
  use Artemis.Schema

  schema "comments" do
    field :body, :string
    field :body_html, :string
    field :title, :string
    field :topic, :string

    belongs_to :user, Artemis.User

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :body,
    :body_html,
    :title,
    :topic
  ]

  def required_fields, do: [
    :body,
    :body_html,
    :title,
    :topic
  ]

  def event_log_fields, do: [
    :id,
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
