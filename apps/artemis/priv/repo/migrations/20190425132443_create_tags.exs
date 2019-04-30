defmodule Artemis.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :description, :text
      add :name, :string
      add :slug, :string
      add :type, :string
    end

    create index(:tags, [:type])

    create unique_index(:tags, [:type, :slug])
    create unique_index(:tags, [:type, :name])
  end
end
