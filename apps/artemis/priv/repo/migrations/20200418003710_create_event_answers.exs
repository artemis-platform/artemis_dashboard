defmodule Artemis.Repo.Migrations.CreateEventAnswers do
  use Ecto.Migration

  def change do
    create table(:event_answers) do
      add :type, :string
      add :value, :text

      add :event_question_id, references(:event_questions, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_answers, [:type])
  end
end
