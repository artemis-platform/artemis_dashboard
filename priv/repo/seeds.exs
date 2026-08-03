# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Artemis.Repo.insert!(%Artemis.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Create demo user (when enabled)
case Artemis.DemoUser.ensure_created() do
  {:ok, :disabled} -> IO.puts("Demo user disabled — skipping.")
  {:ok, _user} -> IO.puts("Demo user ready: #{Artemis.DemoUser.email()}")
  {:error, changeset} -> IO.puts("Demo user error: #{inspect(changeset.errors)}")
end
