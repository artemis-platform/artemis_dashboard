defmodule Artemis.Repo.Migrations.AddUsernameToUsersSearch do
  use Ecto.Migration

  def up do
    # Remove Existing Triggers

    execute("drop trigger tsvectorupdate on users;")

    execute("drop function create_search_data_users();")

    alter table(:users) do
      remove :tsv_search
    end

    # Create Search Index

    alter table(:users) do
      add :tsv_search, :tsvector
    end

    create index(:users, [:tsv_search], name: :users_search_vector, using: "GIN")

    execute("""
      CREATE FUNCTION create_search_data_users() RETURNS trigger AS $$
      begin
        new.tsv_search :=
          to_tsvector(
            'pg_catalog.english',
            coalesce(new.email, ' ') || ' ' ||
            coalesce(new.username, ' ') || ' ' ||
            coalesce(new.name, ' ') || ' ' ||
            coalesce(new.first_name, ' ') || ' ' ||
            coalesce(new.last_name, ' ')
          );
        return new;
      end
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON users FOR EACH ROW EXECUTE PROCEDURE create_search_data_users();
    """)
  end

  def down do
    # 1. Remove Triggers
    execute("drop trigger tsvectorupdate on users;")

    # 2. Remove Functions
    execute("drop function create_search_data_users();")

    # 3. Remove Indexes
    # drop index(:users, [:tsv_search])

    # 4. Remove Columns
    alter table(:users) do
      remove :tsv_search
    end
  end
end
