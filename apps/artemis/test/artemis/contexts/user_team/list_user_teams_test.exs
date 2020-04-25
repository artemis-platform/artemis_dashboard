defmodule Artemis.ListUserTeamsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListUserTeams
  alias Artemis.Repo
  alias Artemis.User
  alias Artemis.UserTeam

  setup do
    Repo.delete_all(UserTeam)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no records exist" do
      assert ListUserTeams.call(Mock.system_user()) == []
    end

    test "returns existing record" do
      user_team = insert(:user_team)

      result = ListUserTeams.call(Mock.system_user())

      assert hd(result).id == user_team.id
    end

    test "returns a list of records" do
      count = 3
      insert_list(count, :user_team)

      user_teams = ListUserTeams.call(Mock.system_user())

      assert length(user_teams) == count
    end
  end

  describe "call - params" do
    setup do
      user_team = insert(:user_team)

      {:ok, user_team: user_team}
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListUserTeams.call(params, Mock.system_user())
        |> Map.from_struct()
        |> Map.keys()

      pagination_keys = [
        :entries,
        :page_number,
        :page_size,
        :total_entries,
        :total_pages
      ]

      assert response_keys == pagination_keys
    end

    test "preload" do
      user = Mock.system_user()

      user_teams = ListUserTeams.call(%{preload: []}, user)
      user_team = hd(user_teams)

      assert user_team.user.__struct__ == Ecto.Association.NotLoaded

      params = %{
        preload: [:user]
      }

      user_teams = ListUserTeams.call(params, user)
      user_team = hd(user_teams)

      assert user_team.user.__struct__ != Ecto.Association.NotLoaded
      assert user_team.user != %User{}
    end
  end
end
