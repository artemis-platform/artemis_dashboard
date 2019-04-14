defmodule Artemis.Repo.Migrations.CreateCommentsWikiPages do
  use Ecto.Migration

  def change do
    create table(:comments_wiki_pages) do
      add :comment_id, references(:comments, on_delete: :delete_all), null: false
      add :wiki_page_id, references(:wiki_pages, on_delete: :delete_all), null: false
    end

    create unique_index(:comments_wiki_pages, [:comment_id, :wiki_page_id])
  end
end
