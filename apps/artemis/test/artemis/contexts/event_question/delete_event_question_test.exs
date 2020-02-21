defmodule Artemis.DeleteEventQuestionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.EventQuestion
  alias Artemis.DeleteEventQuestion

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteEventQuestion.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:event_question)

      %EventQuestion{} = DeleteEventQuestion.call!(record, Mock.system_user())

      assert Repo.get(EventQuestion, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:event_question)

      %EventQuestion{} = DeleteEventQuestion.call!(record.id, Mock.system_user())

      assert Repo.get(EventQuestion, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteEventQuestion.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:event_question)

      {:ok, _} = DeleteEventQuestion.call(record, Mock.system_user())

      assert Repo.get(EventQuestion, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:event_question)

      {:ok, _} = DeleteEventQuestion.call(record.id, Mock.system_user())

      assert Repo.get(EventQuestion, record.id) == nil
    end

    test "deletes associated associations" do
      record = insert(:event_question)
      comments = insert_list(3, :comment, resource_type: "EventQuestion", resource_id: Integer.to_string(record.id))
      _other = insert_list(2, :comment)

      total_before =
        Comment
        |> Repo.all()
        |> length()

      {:ok, _} = DeleteEventQuestion.call(record.id, Mock.system_user())

      assert Repo.get(EventQuestion, record.id) == nil

      total_after =
        Comment
        |> Repo.all()
        |> length()

      assert total_after == total_before - 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, event_question} = DeleteEventQuestion.call(insert(:event_question), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "event_question:deleted",
        payload: %{
          data: ^event_question
        }
      }
    end
  end
end
