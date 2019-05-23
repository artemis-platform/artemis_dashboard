defmodule Artemis.DeleteManyAssociatedCommentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.DeleteManyAssociatedComments

  describe "call!" do
    test "raises an exception record has no comments association" do
      record = insert(:feature)

      assert_raise Artemis.Context.Error, fn ->
        DeleteManyAssociatedComments.call!(record, Mock.system_user())
      end
    end

    test "succeeds if record has no comments" do
      record = insert(:wiki_page, comments: [])

      %Artemis.WikiPage{} = DeleteManyAssociatedComments.call!(record, Mock.system_user())
    end

    test "deletes associated comments when passed valid record" do
      record = insert(:wiki_page)
      comments = insert_list(3, :comment, wiki_pages: [record])

      %Artemis.WikiPage{} = DeleteManyAssociatedComments.call!(record, Mock.system_user())

      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "call" do
    test "returns an error if record has no comments association" do
      record = insert(:feature)

      {:error, _} = DeleteManyAssociatedComments.call(record, Mock.system_user())
    end

    test "succeeds if record has no comments" do
      record = insert(:wiki_page, comments: [])

      %Artemis.WikiPage{} = DeleteManyAssociatedComments.call(record, Mock.system_user())
    end

    test "deletes associated comments when passed valid record" do
      record = insert(:wiki_page)
      comments = insert_list(3, :comment, wiki_pages: [record])

      %Artemis.WikiPage{} = DeleteManyAssociatedComments.call(record, Mock.system_user())

      assert Repo.get(Comment, hd(comments).id) == nil
    end

    test "returns a tuple if passed a tuple" do
      record = insert(:wiki_page)
      comments = insert_list(3, :comment, wiki_pages: [record])

      {:ok, %Artemis.WikiPage{}} = DeleteManyAssociatedComments.call({:ok, record}, Mock.system_user())

      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end
end
