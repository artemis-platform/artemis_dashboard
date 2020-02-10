defmodule Artemis.ListCommentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListComments
  alias Artemis.Repo
  alias Artemis.Comment

  setup do
    Repo.delete_all(Comment)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no comments exist" do
      assert ListComments.call(Mock.system_user()) == []
    end

    test "returns existing comment" do
      comment = insert(:comment)

      assert ListComments.call(Mock.system_user()) == [comment]
    end

    test "returns a list of comments" do
      count = 3
      insert_list(count, :comment)

      comments = ListComments.call(Mock.system_user())

      assert length(comments) == count
    end
  end

  describe "call - params" do
    setup do
      comment = insert(:comment)

      {:ok, comment: comment}
    end

    test "filters" do
      comment = insert(:comment)
      insert_list(3, :comment)

      params = %{}
      results = ListComments.call(params, Mock.system_user())

      assert length(results) == length(Repo.all(Comment))

      # With user belongs to association filter

      params = %{
        filters: %{
          user_id: comment.user_id
        }
      }

      results = ListComments.call(params, Mock.system_user())

      assert length(results) == 1
    end

    test "order" do
      insert_list(3, :comment)

      params = %{order: "title"}
      ascending = ListComments.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListComments.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListComments.call(params, Mock.system_user())
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

    test "query - search" do
      insert(:comment, title: "Four Six", topic: "four-six")
      insert(:comment, title: "Four Two", topic: "four-two")
      insert(:comment, title: "Five Six", topic: "five-six")

      user = Mock.system_user()
      comments = ListComments.call(user)

      assert length(comments) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      comments = ListComments.call(params, user)

      assert length(comments) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      comments = ListComments.call(params, user)

      assert length(comments) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      comments = ListComments.call(params, user)

      assert length(comments) == 0
    end
  end
end
