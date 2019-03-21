defmodule Artemis.Repo.Migrations.CreateWikiRevisions do
  use Ecto.Migration

  def change do
    create table(:wiki_revisions) do
      add :body, :text
      add :body_html, :text
      add :slug, :string
      add :title, :string
      add :user_id, references(:users, on_delete: :nilify_all)
      add :wiki_page_id, references(:wiki_pages, on_delete: :delete_all)
      timestamps()
    end

    create index(:wiki_revisions, [:slug])
  end
end
