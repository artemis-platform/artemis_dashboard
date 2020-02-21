defmodule Artemis.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :description, :text
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:name])
  end
end
