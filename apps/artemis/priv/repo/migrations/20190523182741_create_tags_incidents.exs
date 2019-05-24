defmodule Artemis.Repo.Migrations.CreateTagsIncidents do
  use Ecto.Migration

  def change do
    create table(:tags_incidents) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :incident_id, references(:incidents, on_delete: :delete_all), null: false
    end

    create unique_index(:tags_incidents, [:tag_id, :incident_id])
  end
end
