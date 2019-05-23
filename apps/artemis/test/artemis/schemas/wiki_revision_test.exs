defmodule Artemis.WikiRevisionTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Repo
  alias Artemis.User
  alias Artemis.WikiPage
  alias Artemis.WikiRevision

  @preload [:user]

  describe "associations - user" do
    setup do
      wiki_revision = insert(:wiki_revision)

      {:ok, wiki_revision: Repo.preload(wiki_revision, @preload)}
    end

    test "updating association does not change record", %{wiki_revision: wiki_revision} do
      user = Repo.get(User, wiki_revision.user.id)

      assert user != nil
      assert user.name != "Updated Name"

      params = %{name: "Updated Name"}

      {:ok, user} =
        user
        |> User.changeset(params)
        |> Repo.update()

      assert user != nil
      assert user.name == "Updated Name"

      assert Repo.get(WikiRevision, wiki_revision.id).user_id == user.id
    end

    test "deleting association nilifies record", %{wiki_revision: wiki_revision} do
      assert Repo.get(User, wiki_revision.user.id) != nil

      Repo.delete!(wiki_revision.user)

      assert Repo.get(User, wiki_revision.user.id) == nil
      assert Repo.get(WikiRevision, wiki_revision.id).user_id == nil
    end

    test "deleting record does not remove association", %{wiki_revision: wiki_revision} do
      assert Repo.get(User, wiki_revision.user.id) != nil

      Repo.delete!(wiki_revision)

      assert Repo.get(User, wiki_revision.user.id) != nil
      assert Repo.get(WikiRevision, wiki_revision.id) == nil
    end
  end

  describe "associations - wiki page" do
    setup do
      wiki_revision = insert(:wiki_revision)

      {:ok, wiki_revision: Repo.preload(wiki_revision, @preload)}
    end

    test "updating association does not change record", %{wiki_revision: wiki_revision} do
      wiki_page = Repo.get(WikiPage, wiki_revision.wiki_page.id)

      assert wiki_page != nil
      assert wiki_page.title != "Updated Title"

      params = %{title: "Updated Title"}

      {:ok, wiki_page} =
        wiki_page
        |> WikiPage.changeset(params)
        |> Repo.update()

      assert wiki_page != nil
      assert wiki_page.title == "Updated Title"

      assert Repo.get(WikiRevision, wiki_revision.id).wiki_page_id == wiki_page.id
    end

    test "deleting association deletes record", %{wiki_revision: wiki_revision} do
      assert Repo.get(WikiPage, wiki_revision.wiki_page.id) != nil

      Repo.delete!(wiki_revision.wiki_page)

      assert Repo.get(WikiPage, wiki_revision.wiki_page.id) == nil
      assert Repo.get(WikiRevision, wiki_revision.id) == nil
    end

    test "deleting record does not remove association", %{wiki_revision: wiki_revision} do
      assert Repo.get(WikiPage, wiki_revision.wiki_page.id) != nil

      Repo.delete!(wiki_revision)

      assert Repo.get(WikiPage, wiki_revision.wiki_page.id) != nil
      assert Repo.get(WikiRevision, wiki_revision.id) == nil
    end
  end
end
