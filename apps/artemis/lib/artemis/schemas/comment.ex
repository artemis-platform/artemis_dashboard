defmodule Artemis.Comment do
  use Artemis.Schema
  use Artemis.Schema.SQL
  use Assoc.Schema, repo: Artemis.Repo

  schema "comments" do
    field :body, :string
    field :body_html, :string
    field :resource_id, :string
    field :resource_type, :string
    field :title, :string
    field :topic, :string

    belongs_to :user, Artemis.User

    many_to_many :incidents, Artemis.Incident,
      join_through: "comments_incidents",
      on_delete: :delete_all,
      on_replace: :delete

    many_to_many :wiki_pages, Artemis.WikiPage,
      join_through: "comments_wiki_pages",
      on_delete: :delete_all,
      on_replace: :delete

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

  def updatable_associations,
    do: [
      wiki_pages: Artemis.WikiPage
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
