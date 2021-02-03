defmodule Artemis.Repo.Migrations.CreateKeyValues do
  use Ecto.Migration

  def change do
    create table(:key_values, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :expire_at, :utc_datetime
      add :key, :bytea
      add :size, :integer
      add :value, :bytea

      timestamps(type: :utc_datetime)
    end

    create unique_index(:key_values, [:key])

    create index(:key_values, [:expire_at])
    create index(:key_values, [:size])
  end
end
