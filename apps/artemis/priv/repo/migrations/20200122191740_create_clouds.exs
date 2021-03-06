defmodule Artemis.Repo.Migrations.CreateClouds do
  use Ecto.Migration

  def change do
    create table(:clouds) do
      add :name, :string
      add :slug, :string

      add :customer_id, references(:customers, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:clouds, [:slug])

    create index(:clouds, [:name])
  end
end
