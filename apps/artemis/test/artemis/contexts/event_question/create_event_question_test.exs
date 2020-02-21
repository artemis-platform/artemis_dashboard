defmodule Artemis.CreateEventQuestionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateEventQuestion

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateEventQuestion.call!(%{}, Mock.system_user())
      end
    end

    test "creates a event_question when passed valid params" do
      event_template = insert(:event_template)

      params = params_for(:event_question, event_template: event_template)

      event_question = CreateEventQuestion.call!(params, Mock.system_user())

      assert event_question.title == params.title
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateEventQuestion.call(%{}, Mock.system_user())

      assert errors_on(changeset).title == ["can't be blank"]
    end

    test "creates a event_question when passed valid params" do
      event_template = insert(:event_template)

      params = params_for(:event_question, event_template: event_template)

      {:ok, event_question} = CreateEventQuestion.call(params, Mock.system_user())

      assert event_question.title == params.title
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      event_template = insert(:event_template)

      params = params_for(:event_question, event_template: event_template)

      {:ok, event_question} = CreateEventQuestion.call(params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "event_question:created",
        payload: %{
          data: ^event_question
        }
      }
    end
  end
end
