defmodule Artemis.Repo.Migrations.UpdateUserTeamsWithType do
  use Ecto.Migration

  def change do
    alter table(:user_teams) do
      add :type, :string
    end

    create index(:user_teams, :type)
    create index(:user_teams, [:team_id, :type])
    create index(:user_teams, [:user_id, :type])
  end
end
