defmodule Artemis.Repo.Migrations.CreateMachines do
  use Ecto.Migration

  def change do
    create table(:machines) do
      add :hostname, :string
      add :name, :string
      add :slug, :string

      add :cloud_id, references(:clouds, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:machines, [:name])
    create unique_index(:machines, [:hostname])
    create unique_index(:machines, [:slug])
  end
end
