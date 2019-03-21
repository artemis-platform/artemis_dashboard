defmodule Artemis.WikiPage do
  use Artemis.Schema

  schema "wiki_pages" do
    field :body, :string
    field :body_html, :string
    field :slug, :string
    field :title, :string

    belongs_to :user, Artemis.User

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :body,
    :body_html,
    :slug,
    :title,
    :user_id
  ]

  def required_fields, do: [
    :slug,
    :title
  ]

  def event_log_fields, do: [
    :slug,
    :title
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:slug)
  end
end
