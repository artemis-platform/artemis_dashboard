defmodule Artemis.WikiPageTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Repo
  alias Artemis.User
  alias Artemis.WikiPage

  @preload [:user]

  describe "associations - user" do
    setup do
      wiki_page = insert(:wiki_page)

      {:ok, wiki_page: Repo.preload(wiki_page, @preload)}
    end

    test "updating association does not change record", %{wiki_page: wiki_page} do
      user = Repo.get(User, wiki_page.user.id)

      assert user != nil
      assert user.name != "Updated Name"

      params = %{name: "Updated Name"}

      {:ok, user} = user
        |> User.changeset(params)
        |> Repo.update()

      assert user != nil
      assert user.name == "Updated Name"

      assert Repo.get(WikiPage, wiki_page.id).user_id == user.id
    end

    test "deleting association nilifies record", %{wiki_page: wiki_page} do
      assert Repo.get(User, wiki_page.user.id) != nil

      Repo.delete!(wiki_page.user)

      assert Repo.get(User, wiki_page.user.id) == nil
      assert Repo.get(WikiPage, wiki_page.id).user_id == nil
    end

    test "deleting record does not remove association", %{wiki_page: wiki_page} do
      assert Repo.get(User, wiki_page.user.id) != nil

      Repo.delete!(wiki_page)

      assert Repo.get(User, wiki_page.user.id) != nil
      assert Repo.get(WikiPage, wiki_page.id) == nil
    end
  end
end
