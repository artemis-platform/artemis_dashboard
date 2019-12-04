defmodule Artemis.Repo.Migrations.AddTeamAndServiceToIncidents do
  use Ecto.Migration

  def change do
    alter table(:incidents) do
      add :service_id, :string
      add :service_name, :string
      add :team_id, :string
      add :team_name, :string
    end

    create index(:incidents, :service_id)
    create index(:incidents, [:service_id, :acknowledged_by])
    create index(:incidents, [:service_id, :resolved_by])
    create index(:incidents, [:service_id, :severity])
    create index(:incidents, [:service_id, :source])
    create index(:incidents, [:service_id, :source_uid])
    create index(:incidents, [:service_id, :status])
    create index(:incidents, [:service_id, :triggered_by])

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
