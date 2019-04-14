defmodule Artemis.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text
      add :body_html, :text
      add :title, :string
      add :topic, :string
      add :user_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create index(:comments, [:topic])
  end
end
