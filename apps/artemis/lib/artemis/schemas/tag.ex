defmodule Artemis.Tag do
  use Artemis.Schema
  use Assoc.Schema, repo: Artemis.Repo

  schema "tags" do
    field :description, :string
    field :slug, :string
    field :title, :string
    field :type, :string

    many_to_many :wiki_pages, Artemis.WikiPage, join_through: "tags_wiki_pages", on_delete: :delete_all, on_replace: :delete
  end

  # Callbacks

  def updatable_fields, do: [
    :description,
    :slug,
    :title,
    :type
  ]

  def required_fields, do: [
    :slug,
    :title,
    :type
  ]

  def updatable_associations, do: [
    wiki_pages: Artemis.WikiPage
  ]

  def event_log_fields, do: [
    :id,
    :slug,
    :title,
    :type
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
  end
end
