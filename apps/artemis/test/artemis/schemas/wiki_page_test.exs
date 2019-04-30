defmodule Artemis.WikiPageTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Query
  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.Repo
  alias Artemis.Tag
  alias Artemis.User
  alias Artemis.WikiPage

  @preload [:comments, :tags, :user]

  describe "associations - comments" do
    setup do
      comments = insert_list(3, :comment)
      wiki_page = insert(:wiki_page, comments: comments)

      {:ok, comments: comments, wiki_page: Repo.preload(wiki_page, @preload)}
    end

    test "updating association does not change record", %{wiki_page: wiki_page} do
      assert length(wiki_page.comments) == 3

      comment = Repo.get(Comment, hd(wiki_page.comments).id)

      assert comment != nil
      assert comment.title != "Updated Title"

      params = %{title: "Updated Title"}

      {:ok, comment} = comment
        |> Comment.changeset(params)
        |> Repo.update()

      assert comment != nil
      assert comment.title == "Updated Title"

      wiki_page = WikiPage
        |> preload(^@preload)
        |> Repo.get(wiki_page.id)

      assert length(wiki_page.comments) == 3
    end

    test "deleting association does not change record", %{wiki_page: wiki_page} do
      assert length(wiki_page.comments) == 3

      comment = Repo.get(Comment, hd(wiki_page.comments).id)

      Repo.delete!(comment)

      wiki_page = WikiPage
        |> preload(^@preload)
        |> Repo.get(wiki_page.id)

      assert length(wiki_page.comments) == 2
    end

    test "deleting record only removes the join table, not the associated records", %{wiki_page: wiki_page} do
      # Only the join table records are removed. This is a limitation of Ecto many_to_many:
      # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
      #
      comment = Comment
        |> preload([:wiki_pages])
        |> Repo.get(hd(wiki_page.comments).id)

      assert !is_nil(comment)
      assert length(comment.wiki_pages) == 1

      Repo.delete!(wiki_page)

      comment = Comment
        |> preload([:wiki_pages])
        |> Repo.get(hd(wiki_page.comments).id)

      assert !is_nil(comment)
      assert length(comment.wiki_pages) == 0
    end
  end

  describe "associations - tags" do
    setup do
      tags = insert_list(3, :tag)
      wiki_page = insert(:wiki_page, tags: tags)

      {:ok, tags: tags, wiki_page: Repo.preload(wiki_page, @preload)}
    end

    test "updating association does not change record", %{wiki_page: wiki_page} do
      assert length(wiki_page.tags) == 3

      tag = Repo.get(Tag, hd(wiki_page.tags).id)

      assert tag != nil
      assert tag.name != "Updated Name"

      params = %{name: "Updated Name"}

      {:ok, tag} = tag
        |> Tag.changeset(params)
        |> Repo.update()

      assert tag != nil
      assert tag.name == "Updated Name"

      wiki_page = WikiPage
        |> preload(^@preload)
        |> Repo.get(wiki_page.id)

      assert length(wiki_page.tags) == 3
    end

    test "deleting association does not change record", %{wiki_page: wiki_page} do
      assert length(wiki_page.tags) == 3

      tag = Repo.get(Tag, hd(wiki_page.tags).id)

      Repo.delete!(tag)

      wiki_page = WikiPage
        |> preload(^@preload)
        |> Repo.get(wiki_page.id)

      assert length(wiki_page.tags) == 2
    end

    test "deleting record only removes the join table, not the associated records", %{wiki_page: wiki_page} do
      # Only the join table records are removed. This is a limitation of Ecto many_to_many:
      # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
      #
      tag = Tag
        |> preload([:wiki_pages])
        |> Repo.get(hd(wiki_page.tags).id)

      assert !is_nil(tag)
      assert length(tag.wiki_pages) == 1

      Repo.delete!(wiki_page)

      tag = Tag
        |> preload([:wiki_pages])
        |> Repo.get(hd(wiki_page.tags).id)

      assert !is_nil(tag)
      assert length(tag.wiki_pages) == 0
    end
  end

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
