defmodule Artemis.Repo.Migrations.CreateIncidentsSearch do
  use Ecto.Migration

  def up do
    # 1. Create Search Data Column
    #
    # Define a column to store full text search data
    #
    alter table(:incidents) do
      add :tsv_search, :tsvector
    end

    # 2. Create Search Data Index
    #
    # Create a GIN index on the full text search data column
    #
    create index(:incidents, [:tsv_search], name: :incidents_search_vector, using: "GIN")

    # 3. Define a Coalesce Function
    #
    # Coalesce the searchable fields into a single, space-separted, value. In
    # the example below the following user attributes are included in search:
    #
    # - email
    # - name
    # - first_name
    # - last_name
    #
    execute("""
      CREATE FUNCTION create_search_data_incidents() RETURNS trigger AS $$
      begin
        new.tsv_search :=
          to_tsvector(
            'pg_catalog.english',
            coalesce(new.title, ' ') || ' ' ||
            coalesce(new.source_uid, ' ') || ' ' ||
            coalesce(new.severity, ' ') || ' ' ||
            coalesce(new.status, ' ') || ' ' ||
            coalesce(new.description, ' ')
          );
        return new;
      end
      $$ LANGUAGE plpgsql;
    """)

    # 4. Trigger the Function
    #
    # Call the function on `INSERT` and `UPDATE` actions
    #
    execute("""
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON incidents FOR EACH ROW EXECUTE PROCEDURE create_search_data_incidents();
    """)
  end

  def down do
    # 1. Remove Triggers
    execute("drop function create_search_data_incidents();")

    # 2. Remove Functions
    execute("drop trigger tsvectorupdate on incidents;")

    # 3. Remove Indexes
    drop index(:incidents, [:tsv_search])

    # 4. Remove Columns
    alter table(:incidents) do
      remove :tsv_search
    end
  end
end
