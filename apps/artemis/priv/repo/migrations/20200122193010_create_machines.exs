defmodule Artemis.Repo.Migrations.CreateMachines do
  use Ecto.Migration

  def change do
    create table(:machines) do
      add :cpu_total, :integer
      add :cpu_used, :integer
      add :hostname, :string
      add :name, :string
      add :ram_total, :integer
      add :ram_used, :integer
      add :slug, :string

      add :cloud_id, references(:clouds, on_delete: :nilify_all)
      add :data_center_id, references(:data_centers, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:machines, [:slug])

    create index(:machines, [:hostname])
    create index(:machines, [:name])
  end
end
