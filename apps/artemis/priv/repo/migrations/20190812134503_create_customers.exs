defmodule Artemis.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string
      add :notes, :text
      add :notes_html, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:customers, [:name])
  end
end
