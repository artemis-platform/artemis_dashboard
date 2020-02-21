defmodule Artemis.EventQuestionTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.EventQuestion
  alias Artemis.EventTemplate

  @preload [:event_template]

  describe "attributes - constraints" do
    test "required associations" do
      params = params_for(:event_question)

      {:error, changeset} =
        %EventQuestion{}
        |> EventQuestion.changeset(params)
        |> Repo.insert()

      assert errors_on(changeset) == %{event_template_id: ["can't be blank"]}
    end

    test "type must in allowed types" do
      event_template = insert(:event_template)

      params = params_for(:event_question, event_template: event_template, type: "test-invalid-type")

      {:error, changeset} =
        %EventQuestion{}
        |> EventQuestion.changeset(params)
        |> Repo.insert()

      assert errors_on(changeset) == %{type: ["is invalid"]}
    end
  end

  describe "associations - event_template" do
    setup do
      event_question = insert(:event_question)

      {:ok, event_question: Repo.preload(event_question, @preload)}
    end

    test "deleting association removes record", %{event_question: event_question} do
      assert Repo.get(EventTemplate, event_question.event_template.id) != nil

      Repo.delete!(event_question.event_template)

      assert Repo.get(EventTemplate, event_question.event_template.id) == nil
      assert Repo.get(EventQuestion, event_question.id) == nil
    end

    test "deleting record does not remove association", %{event_question: event_question} do
      assert Repo.get(EventTemplate, event_question.event_template.id) != nil

      Repo.delete!(event_question)

      assert Repo.get(EventTemplate, event_question.event_template.id) != nil
      assert Repo.get(EventQuestion, event_question.id) == nil
    end
  end
end
