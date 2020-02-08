defmodule Artemis.Repo.Migrations.DropCommentsIncidents do
  use Ecto.Migration

  def change do
    drop table("comments_incidents")
  end
end
