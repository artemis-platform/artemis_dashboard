defmodule Artemis.Repo.Migrations.AddResourceToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :resource_id, :string
      add :resource_type, :string
    end

    create index(:comments, :resource_id)
    create index(:comments, :resource_type)
    create index(:comments, [:resource_id, :resource_type])
    create index(:comments, [:resource_type, :resource_id])
  end
end
