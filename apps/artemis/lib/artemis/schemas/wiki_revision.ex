defmodule Artemis.WikiRevision do
  use Artemis.Schema
  use Artemis.Schema.SQL

  schema "wiki_revisions" do
    field :body, :string
    field :body_html, :string
    field :section, :string
    field :slug, :string
    field :title, :string
    field :weight, :integer

    belongs_to :user, Artemis.User
    belongs_to :wiki_page, Artemis.WikiPage

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :body,
      :body_html,
      :section,
      :slug,
      :title,
      :weight,
      :user_id,
      :wiki_page_id
    ]

  def required_fields,
    do: [
      :section,
      :slug,
      :title
    ]

  def event_log_fields,
    do: [
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
