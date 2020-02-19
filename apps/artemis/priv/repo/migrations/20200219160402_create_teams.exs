defmodule Artemis.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :description, :text
      add :name, :string
      add :slug, :string
      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:slug])
    create unique_index(:teams, [:name])
  end
end
