defmodule Artemis.Repo.Migrations.CreateWikiPages do
  use Ecto.Migration

  def change do
    create table(:wiki_pages) do
      add :body, :text
      add :body_html, :text
      add :slug, :string
      add :title, :string
      add :user_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:wiki_pages, [:slug])
  end
end
