defmodule Artemis.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
