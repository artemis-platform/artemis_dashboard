defmodule Artemis.UpdateCommentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateComment

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:comment)

      assert_raise Artemis.Context.Error, fn ->
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
      invalid_id = 50_000_000
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

    test "supports markdown" do
      comment = insert(:comment)
      params = params_for(:comment, body: "# Test")

      {:ok, updated} = UpdateComment.call(comment.id, params, Mock.system_user())

      assert updated.body == params.body
      assert updated.body_html == "<h1>Test</h1>\n"
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
