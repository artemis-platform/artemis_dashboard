defmodule Artemis.Repo.Migrations.CreateEventTemplates do
  use Ecto.Migration

  def change do
    create table(:event_templates) do
      add :active, :boolean
      add :title, :string

      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_templates, [:title])
  end
end
