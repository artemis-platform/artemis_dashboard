defmodule Artemis.TeamTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Repo
  alias Artemis.Team
  alias Artemis.UserTeam

  @preload [:user_teams, :users]

  describe "attributes - constraints" do
    test "name must be unique" do
      existing = insert(:team)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:team, name: existing.name)
      end
    end

    test "slug must be unique" do
      existing = insert(:team)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:team, slug: existing.slug)
      end
    end
  end

  describe "associations - user teams" do
    setup do
      team = insert(:team)

      insert_list(3, :user_team, team: team)

      {:ok, team: Repo.preload(team, @preload)}
    end

    test "update associations", %{team: team} do
      new_user = insert(:user)

      assert length(team.user_teams) == 3

      {:ok, updated} =
        team
        |> Team.associations_changeset(%{user_teams: [%{team_id: team.id, user_id: new_user.id}]})
        |> Repo.update()

      assert length(updated.user_teams) == 1
      assert hd(updated.user_teams).user_id == new_user.id
    end

    test "deleting association does not remove record", %{team: team} do
      assert Repo.get(Team, team.id) != nil
      assert length(team.user_teams) == 3

      Enum.map(team.user_teams, &Repo.delete(&1))

      team =
        Team
        |> preload(^@preload)
        |> Repo.get(team.id)

      assert Repo.get(Team, team.id) != nil
      assert length(team.user_teams) == 0
    end

    test "deleting record removes associations", %{team: team} do
      assert Repo.get(Team, team.id) != nil
      assert length(team.user_teams) == 3

      Repo.delete(team)

      assert Repo.get(Team, team.id) == nil

      Enum.map(team.user_teams, fn user_team ->
        assert Repo.get(UserTeam, user_team.id) == nil
      end)
    end
  end
end
