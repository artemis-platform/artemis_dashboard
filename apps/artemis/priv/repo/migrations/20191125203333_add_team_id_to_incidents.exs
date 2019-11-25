defmodule Artemis.Repo.Migrations.AddTeamIdToIncidents do
  use Ecto.Migration

  def change do
    alter table(:incidents) do
      add :team_id, :string
    end

    create index(:incidents, :team_id)
    create index(:incidents, [:team_id, :acknowledged_by])
    create index(:incidents, [:team_id, :resolved_by])
    create index(:incidents, [:team_id, :severity])
    create index(:incidents, [:team_id, :source])
    create index(:incidents, [:team_id, :source_uid])
    create index(:incidents, [:team_id, :status])
    create index(:incidents, [:team_id, :triggered_by])
  end
end
