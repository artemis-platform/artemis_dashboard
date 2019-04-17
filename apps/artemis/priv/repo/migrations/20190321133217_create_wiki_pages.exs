defmodule Artemis.Repo.Migrations.CreateWikiPages do
  use Ecto.Migration

  def change do
    create table(:wiki_pages) do
      add :body, :text
      add :body_html, :text
      add :section, :string
      add :slug, :string
      add :title, :string
      add :weight, :integer
      add :user_id, references(:users, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create index(:wiki_pages, [:section])
    create index(:wiki_pages, [:section, :weight])
    create index(:wiki_pages, [:weight])
    create unique_index(:wiki_pages, [:slug])
  end
end
