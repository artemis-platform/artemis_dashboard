defmodule Artemis.WikiPage do
  use Artemis.Schema

  schema "wiki_pages" do
    field :body, :string
    field :body_html, :string
    field :section, :string
    field :slug, :string
    field :title, :string
    field :weight, :integer

    belongs_to :user, Artemis.User
    has_many :wiki_revisions, Artemis.WikiRevision, on_delete: :delete_all

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :body,
    :body_html,
    :section,
    :slug,
    :title,
    :weight,
    :user_id
  ]

  def required_fields, do: [
    :section,
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
