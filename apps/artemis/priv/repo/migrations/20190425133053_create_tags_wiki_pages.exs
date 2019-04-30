defmodule Artemis.Repo.Migrations.CreateTagsWikiPages do
  use Ecto.Migration

  def change do
    create table(:tags_wiki_pages) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :wiki_page_id, references(:wiki_pages, on_delete: :delete_all), null: false
    end

    create unique_index(:tags_wiki_pages, [:tag_id, :wiki_page_id])
  end
end
