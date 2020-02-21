defmodule Artemis.GetEventQuestionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetEventQuestion

  setup do
    event_question = insert(:event_question)

    {:ok, event_question: event_question}
  end

  describe "call" do
    test "returns nil event_question not found" do
      invalid_id = 50_000_000

      assert GetEventQuestion.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds event_question by id", %{event_question: event_question} do
      assert GetEventQuestion.call(event_question.id, Mock.system_user()).id == event_question.id
    end

    test "finds record by keyword list", %{event_question: event_question} do
      assert GetEventQuestion.call([title: event_question.title], Mock.system_user()).id == event_question.id
    end
  end

  describe "call!" do
    test "raises an exception event_question not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetEventQuestion.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds event_question by id", %{event_question: event_question} do
      assert GetEventQuestion.call!(event_question.id, Mock.system_user()).id == event_question.id
    end
  end
end
