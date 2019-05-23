defmodule Artemis.Repo.Migrations.CreateCommentsIncidents do
  use Ecto.Migration

  def change do
    create table(:comments_incidents) do
      add :comment_id, references(:comments, on_delete: :delete_all), null: false
      add :incident_id, references(:incidents, on_delete: :delete_all), null: false
    end

    create unique_index(:comments_incidents, [:comment_id, :incident_id])
  end
end
