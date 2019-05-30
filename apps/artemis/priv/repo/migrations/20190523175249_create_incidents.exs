defmodule Artemis.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents) do
      add :acknowledged_at, :utc_datetime
      add :acknowledged_by, :text
      add :description, :text
      add :meta, :map
      add :resolved_at, :utc_datetime
      add :resolved_by, :text
      add :severity, :string
      add :source, :string
      add :source_uid, :string
      add :status, :string
      add :time_to_acknowledge, :integer
      add :time_to_resolve, :integer
      add :title, :text
      add :triggered_at, :utc_datetime
      add :triggered_by, :text
      timestamps(type: :utc_datetime)
    end

    create index(:incidents, :acknowledged_by)
    create index(:incidents, :resolved_by)
    create index(:incidents, :severity)
    create index(:incidents, :source)
    create index(:incidents, :source_uid)
    create index(:incidents, :status)
    create index(:incidents, :triggered_by)

    create unique_index(:incidents, [:source, :source_uid], name: "incidents_source_uid_unique_index")

    execute "CREATE INDEX index_incidents_meta ON incidents USING gin(meta jsonb_path_ops);"
  end
end
