defmodule Artemis.UpdateEventQuestionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateEventQuestion

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:event_question)

      assert_raise Artemis.Context.Error, fn ->
        UpdateEventQuestion.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      event_question = insert(:event_question)
      params = %{}

      updated = UpdateEventQuestion.call!(event_question, params, Mock.system_user())

      assert updated.title == event_question.title
    end

    test "updates a record when passed valid params" do
      event_question = insert(:event_question)
      params = params_for(:event_question)

      updated = UpdateEventQuestion.call!(event_question, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      event_question = insert(:event_question)
      params = params_for(:event_question)

      updated = UpdateEventQuestion.call!(event_question.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:event_question)

      {:error, _} = UpdateEventQuestion.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      event_question = insert(:event_question)
      params = %{}

      {:ok, updated} = UpdateEventQuestion.call(event_question, params, Mock.system_user())

      assert updated.title == event_question.title
    end

    test "updates a record when passed valid params" do
      event_question = insert(:event_question)
      params = params_for(:event_question)

      {:ok, updated} = UpdateEventQuestion.call(event_question, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      event_question = insert(:event_question)
      params = params_for(:event_question)

      {:ok, updated} = UpdateEventQuestion.call(event_question.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      event_question = insert(:event_question)
      params = params_for(:event_question)

      {:ok, updated} = UpdateEventQuestion.call(event_question, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "event_question:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
