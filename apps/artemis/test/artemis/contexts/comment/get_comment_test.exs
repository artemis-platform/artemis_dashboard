defmodule Artemis.GetCommentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetComment

  setup do
    user = insert(:user)

    comment =
      :comment
      |> insert(user: user)
      |> with_wiki_page()

    {:ok, comment: comment, user: user}
  end

  describe "access permissions" do
    test "returns nil with no permissions", %{comment: comment, user: user} do
      nil = GetComment.call(comment.id, user)
    end

    test "requires access:self permission to return own record", %{comment: comment, user: user} do
      with_permission(user, "comments:access:self")

      assert GetComment.call(comment.id, user).id == comment.id
    end

    test "requires access:all permission to return other records", %{user: user} do
      with_permission(user, "comments:access:all")

      other_user = insert(:user)
      other_comment = insert(:comment, user: other_user)

      assert GetComment.call(other_comment.id, user).id == other_comment.id
    end
  end

  describe "call" do
    test "returns nil comment not found" do
      invalid_id = 50_000_000

      assert GetComment.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds comment by id", %{comment: comment} do
      assert GetComment.call(comment.id, Mock.system_user()) == comment
    end

    test "finds comment keyword list", %{comment: comment} do
      assert GetComment.call([title: comment.title, topic: comment.topic], Mock.system_user()) == comment
    end
  end

  describe "call - options" do
    test "preload", %{comment: comment} do
      comment = GetComment.call(comment.id, Mock.system_user())

      assert !is_list(comment.wiki_pages)
      assert comment.wiki_pages.__struct__ == Ecto.Association.NotLoaded

      options = [
        preload: [:wiki_pages]
      ]

      comment = GetComment.call(comment.id, Mock.system_user(), options)

      assert is_list(comment.wiki_pages)
    end
  end

  describe "call!" do
    test "raises an exception comment not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetComment.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds comment by id", %{comment: comment} do
      assert GetComment.call!(comment.id, Mock.system_user()) == comment
    end
  end
end
