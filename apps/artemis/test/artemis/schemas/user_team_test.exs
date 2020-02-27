defmodule Artemis.UserTeamTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Repo
  alias Artemis.Team
  alias Artemis.UserTeam
  alias Artemis.User

  @preload [:created_by, :team, :user]

  describe "associations - created by" do
    setup do
      user_team = insert(:user_team)

      {:ok, user_team: Repo.preload(user_team, @preload)}
    end

    test "deleting association does not remove record and nilifies foreign key", %{user_team: user_team} do
      assert Repo.get(User, user_team.created_by.id) != nil
      assert user_team.created_by != nil

      Repo.delete!(user_team.created_by)

      assert Repo.get(User, user_team.created_by.id) == nil

      user_team =
        UserTeam
        |> preload(^@preload)
        |> Repo.get(user_team.id)

      assert user_team.created_by == nil
    end

    test "deleting record does not remove association", %{user_team: user_team} do
      assert Repo.get(User, user_team.created_by.id) != nil

      Repo.delete!(user_team)

      assert Repo.get(User, user_team.created_by.id) != nil
      assert Repo.get(UserTeam, user_team.id) == nil
    end
  end

  describe "associations - team" do
    setup do
      user_team = insert(:user_team)

      {:ok, user_team: Repo.preload(user_team, @preload)}
    end

    test "deleting association removes record", %{user_team: user_team} do
      assert Repo.get(Team, user_team.team.id) != nil

      Repo.delete!(user_team.team)

      assert Repo.get(Team, user_team.team.id) == nil
      assert Repo.get(UserTeam, user_team.id) == nil
    end

    test "deleting record does not remove association", %{user_team: user_team} do
      assert Repo.get(Team, user_team.team.id) != nil

      Repo.delete!(user_team)

      assert Repo.get(Team, user_team.team.id) != nil
      assert Repo.get(UserTeam, user_team.id) == nil
    end
  end

  describe "associations - user" do
    setup do
      user_team = insert(:user_team)

      {:ok, user_team: Repo.preload(user_team, @preload)}
    end

    test "deleting association removes record", %{user_team: user_team} do
      assert Repo.get(User, user_team.user.id) != nil

      Repo.delete!(user_team.user)

      assert Repo.get(User, user_team.user.id) == nil
      assert Repo.get(UserTeam, user_team.id) == nil
    end

    test "deleting record does not remove association", %{user_team: user_team} do
      assert Repo.get(User, user_team.user.id) != nil

      Repo.delete!(user_team)

      assert Repo.get(User, user_team.user.id) != nil
      assert Repo.get(UserTeam, user_team.id) == nil
    end
  end
end
