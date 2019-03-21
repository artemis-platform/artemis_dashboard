defmodule Artemis.WikiRevision do
  use Artemis.Schema

  schema "wiki_revisions" do
    field :body, :string
    field :slug, :string
    field :title, :string

    belongs_to :user, Artemis.User
    belongs_to :wiki_page, Artemis.WikiPage

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :body,
    :slug,
    :title,
    :user_id,
    :wiki_page_id
  ]

  def required_fields, do: [
    :slug,
    :title
  ]

  def event_log_fields, do: [
    :slug,
    :title,
    :wiki_page_id
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:wiki_page_id)
    |> unique_constraint(:slug)
  end
end
