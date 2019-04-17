defmodule Artemis.DeleteCommentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.DeleteComment

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000

      assert_raise Artemis.Context.Error, fn () ->
        DeleteComment.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:comment)

      %Comment{} = DeleteComment.call!(record, Mock.system_user())

      assert Repo.get(Comment, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:comment)

      %Comment{} = DeleteComment.call!(record.id, Mock.system_user())

      assert Repo.get(Comment, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50000000

      {:error, _} = DeleteComment.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:comment)

      {:ok, _} = DeleteComment.call(record, Mock.system_user())

      assert Repo.get(Comment, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:comment)

      {:ok, _} = DeleteComment.call(record.id, Mock.system_user())

      assert Repo.get(Comment, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, comment} = DeleteComment.call(insert(:comment), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "comment:deleted",
        payload: %{
          data: ^comment
        }
      }
    end
  end
end
