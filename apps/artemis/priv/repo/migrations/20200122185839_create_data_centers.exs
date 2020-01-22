defmodule Artemis.Repo.Migrations.CreateDataCenters do
  use Ecto.Migration

  def change do
    create table(:data_centers) do
      add :country, :string
      add :latitude, :string
      add :longitude, :string
      add :name, :string
      add :slug, :string
      timestamps(type: :utc_datetime)
    end

    create unique_index(:data_centers, [:country])
    create unique_index(:data_centers, [:latitude, :longitude])
    create unique_index(:data_centers, [:name])
    create unique_index(:data_centers, [:slug])
  end
end
