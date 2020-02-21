defmodule Artemis.Repo.Migrations.CreateEventQuestions do
  use Ecto.Migration

  def change do
    create table(:event_questions) do
      add :active, :boolean
      add :title, :string
      add :type, :string

      add :event_template_id, references(:event_templates, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_questions, [:title])
    create index(:event_questions, [:type])
  end
end
