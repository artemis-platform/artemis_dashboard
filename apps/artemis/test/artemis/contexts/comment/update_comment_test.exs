defmodule Artemis.UpdateCommentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateComment

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000
      params = params_for(:comment)

      assert_raise Artemis.Context.Error, fn () ->
        UpdateComment.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      comment = insert(:comment)
      params = %{}

      updated = UpdateComment.call!(comment, params, Mock.system_user())

      assert updated.title == comment.title
    end

    test "updates a record when passed valid params" do
      comment = insert(:comment)
      params = params_for(:comment)

      updated = UpdateComment.call!(comment, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      comment = insert(:comment)
      params = params_for(:comment)

      updated = UpdateComment.call!(comment.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50000000
      params = params_for(:comment)

      {:error, _} = UpdateComment.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      comment = insert(:comment)
      params = %{}

      {:ok, updated} = UpdateComment.call(comment, params, Mock.system_user())

      assert updated.title == comment.title
    end

    test "updates a record when passed valid params" do
      comment = insert(:comment)
      params = params_for(:comment)

      {:ok, updated} = UpdateComment.call(comment, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      comment = insert(:comment)
      params = params_for(:comment)

      {:ok, updated} = UpdateComment.call(comment.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call - associations" do
    test "adds updatable associations and updates record values" do
      comment = insert(:comment)
      wiki_page = insert(:wiki_page)

      comment = Repo.preload(comment, [:wiki_pages])

      assert comment.wiki_pages == []

      # Add Association

      params = %{
        id: comment.id,
        body: comment.body,
        title: "Updated Title",
        wiki_pages: [
          %{id: wiki_page.id}
        ]
      }

      {:ok, updated} = UpdateComment.call(comment.id, params, Mock.system_user())

      assert updated.title == "Updated Title"
      assert updated.wiki_pages != []
    end

    test "removes associations when explicitly passed an empty value" do
      comment = :comment
        |> insert
        |> with_wiki_page

      comment = Repo.preload(comment, [:wiki_pages])

      assert length(comment.wiki_pages) == 1

      # Keeps existing associations if the association key is not passed

      params = %{
        id: comment.id,
        title: "New Title"
      }

      {:ok, updated} = UpdateComment.call(comment.id, params, Mock.system_user())

      assert length(updated.wiki_pages) == 1

      # Only removes associations when the association key is explicitly passed

      params = %{
        id: comment.id,
        wiki_pages: []
      }

      {:ok, updated} = UpdateComment.call(comment.id, params, Mock.system_user())

      assert length(updated.wiki_pages) == 0
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      comment = insert(:comment)
      params = params_for(:comment)

      {:ok, updated} = UpdateComment.call(comment, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "comment:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
