defmodule Artemis.EventAnswerTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.EventAnswer
  alias Artemis.EventInstance
  alias Artemis.EventQuestion
  alias Artemis.User

  @preload [:event_instance, :event_question, :user]

  describe "attributes - constraints" do
    test "required associations" do
      params =
        :event_answer
        |> params_for()
        |> Map.delete(:event_instance_id)
        |> Map.delete(:event_question_id)
        |> Map.delete(:user_id)

      {:error, changeset} =
        %EventAnswer{}
        |> EventAnswer.changeset(params)
        |> Repo.insert()

      expected_errors = %{
        event_instance_id: ["can't be blank"],
        event_question_id: ["can't be blank"],
        user_id: ["can't be blank"]
      }

      assert errors_on(changeset) == expected_errors
    end
  end

  describe "associations - event_instance" do
    setup do
      event_answer = insert(:event_answer)

      {:ok, event_answer: Repo.preload(event_answer, @preload)}
    end

    test "deleting association removes record", %{event_answer: event_answer} do
      assert Repo.get(EventInstance, event_answer.event_instance.id) != nil

      Repo.delete!(event_answer.event_instance)

      assert Repo.get(EventInstance, event_answer.event_instance.id) == nil
      assert Repo.get(EventAnswer, event_answer.id) == nil
    end

    test "deleting record does not remove association", %{event_answer: event_answer} do
      assert Repo.get(EventInstance, event_answer.event_instance.id) != nil

      Repo.delete!(event_answer)

      assert Repo.get(EventInstance, event_answer.event_instance.id) != nil
      assert Repo.get(EventAnswer, event_answer.id) == nil
    end
  end

  describe "associations - event_question" do
    setup do
      event_answer = insert(:event_answer)

      {:ok, event_answer: Repo.preload(event_answer, @preload)}
    end

    test "deleting association removes record", %{event_answer: event_answer} do
      assert Repo.get(EventQuestion, event_answer.event_question.id) != nil

      Repo.delete!(event_answer.event_question)

      assert Repo.get(EventQuestion, event_answer.event_question.id) == nil
      assert Repo.get(EventAnswer, event_answer.id) == nil
    end

    test "deleting record does not remove association", %{event_answer: event_answer} do
      assert Repo.get(EventQuestion, event_answer.event_question.id) != nil

      Repo.delete!(event_answer)

      assert Repo.get(EventQuestion, event_answer.event_question.id) != nil
      assert Repo.get(EventAnswer, event_answer.id) == nil
    end
  end

  describe "associations - user" do
    setup do
      event_answer = insert(:event_answer)

      {:ok, event_answer: Repo.preload(event_answer, @preload)}
    end

    test "deleting association nilifies record", %{event_answer: event_answer} do
      assert Repo.get(User, event_answer.user.id) != nil

      Repo.delete!(event_answer.user)

      assert Repo.get(User, event_answer.user.id) == nil

      updated_record =
        EventAnswer
        |> Repo.get(event_answer.id)
        |> Repo.preload(@preload)

      assert updated_record.user == nil
    end

    test "deleting record does not remove association", %{event_answer: event_answer} do
      assert Repo.get(User, event_answer.user.id) != nil

      Repo.delete!(event_answer)

      assert Repo.get(User, event_answer.user.id) != nil
      assert Repo.get(EventAnswer, event_answer.id) == nil
    end
  end
end
