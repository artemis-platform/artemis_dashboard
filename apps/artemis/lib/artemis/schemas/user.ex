defmodule Artemis.User do
  use Artemis.Schema
  use Assoc.Schema, repo: Artemis.Repo

  schema "users" do
    field :client_key, :string
    field :client_secret, :string
    field :description, :string
    field :email, :string
    field :first_name, :string
    field :image, :string
    field :last_log_in_at, :utc_datetime
    field :last_name, :string
    field :name, :string

    has_many :auth_providers, Artemis.AuthProvider, on_delete: :delete_all
    has_many :comments, Artemis.Comment, on_delete: :nilify_all
    has_many :user_roles, Artemis.UserRole, on_delete: :delete_all, on_replace: :delete
    has_many :roles, through: [:user_roles, :role]
    has_many :permissions, through: [:roles, :permissions]
    has_many :wiki_pages, Artemis.WikiPage, on_delete: :nilify_all
    has_many :wiki_revisions, Artemis.WikiRevision, on_delete: :nilify_all

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :client_key,
    :client_secret,
    :description,
    :email,
    :name,
    :first_name,
    :image,
    :last_log_in_at,
    :last_name
  ]

  def required_fields, do: [
    :email
  ]

  def updatable_associations, do: [
    user_roles: Artemis.UserRole
  ]

  def event_log_fields, do: [
    :id,
    :name
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> unique_constraint(:email)
  end
end
