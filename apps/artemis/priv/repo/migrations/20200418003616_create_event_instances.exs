defmodule Artemis.Repo.Migrations.CreateEventInstances do
  use Ecto.Migration

  def change do
    create table(:event_instances) do
      add :description, :text
      add :slug, :string
      add :title, :string

      add :event_template_id, references(:event_templates, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:event_instances, [:event_template_id, :slug])

    create index(:event_instances, [:slug])
    create index(:event_instances, [:title])
  end
end
