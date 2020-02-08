defmodule Artemis.Repo.Migrations.DropCommentsWikiPages do
  use Ecto.Migration

  def change do
    drop table("comments_wiki_pages")
  end
end
