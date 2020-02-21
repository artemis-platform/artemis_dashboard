defmodule Artemis.ListEventQuestionsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListEventQuestions
  alias Artemis.Repo
  alias Artemis.EventQuestion

  setup do
    Repo.delete_all(EventQuestion)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no event_questions exist" do
      assert ListEventQuestions.call(Mock.system_user()) == []
    end

    test "returns existing event_question" do
      event_question = insert(:event_question)

      event_questions = ListEventQuestions.call(Mock.system_user())

      assert length(event_questions) == 1
      assert hd(event_questions).id == event_question.id
    end

    test "returns a list of event_questions" do
      count = 3
      insert_list(count, :event_question)

      event_questions = ListEventQuestions.call(Mock.system_user())

      assert length(event_questions) == count
    end
  end

  describe "call - params" do
    setup do
      event_question = insert(:event_question)

      {:ok, event_question: event_question}
    end

    test "order" do
      insert_list(3, :event_question)

      params = %{order: "title"}
      ascending = ListEventQuestions.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListEventQuestions.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListEventQuestions.call(params, Mock.system_user())
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
      insert(:event_question, title: "Four Six")
      insert(:event_question, title: "Four Two")
      insert(:event_question, title: "Five Six")

      user = Mock.system_user()
      event_questions = ListEventQuestions.call(user)

      assert length(event_questions) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      event_questions = ListEventQuestions.call(params, user)

      assert length(event_questions) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      event_questions = ListEventQuestions.call(params, user)

      assert length(event_questions) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      event_questions = ListEventQuestions.call(params, user)

      assert length(event_questions) == 0
    end
  end

  describe "cache" do
    setup do
      ListEventQuestions.reset_cache()
      ListEventQuestions.call_with_cache(Mock.system_user())

      {:ok, []}
    end

    test "uses default simple cache key callback" do
      user = Mock.system_user()
      key = ListEventQuestions.call_with_cache(user).key

      assert key == []
      assert length(key) == 0

      params = %{
        paginate: true
      }

      key = ListEventQuestions.call_with_cache(params, user).key

      assert is_list(key)
      assert key == [params]
    end

    test "uses default context cache options" do
      defaults = Artemis.CacheInstance.default_cachex_options()
      cachex_options = Artemis.CacheInstance.get_cachex_options(ListEventQuestions)

      assert cachex_options[:expiration] == Keyword.fetch!(defaults, :expiration)
      assert cachex_options[:limit] == Keyword.fetch!(defaults, :limit)
    end

    test "returns a cached result" do
      initial_call = ListEventQuestions.call_with_cache(Mock.system_user())

      assert initial_call.__struct__ == Artemis.CacheInstance.CacheEntry
      assert is_list(initial_call.data)
      assert initial_call.inserted_at != nil
      assert initial_call.key != nil

      cache_hit = ListEventQuestions.call_with_cache(Mock.system_user())

      assert is_list(cache_hit.data)
      assert cache_hit.inserted_at != nil
      assert cache_hit.inserted_at == initial_call.inserted_at
      assert cache_hit.key != nil

      params = %{
        paginate: true
      }

      different_key = ListEventQuestions.call_with_cache(params, Mock.system_user())

      assert different_key.data.__struct__ == Scrivener.Page
      assert is_list(different_key.data.entries)
      assert different_key.inserted_at != nil
      assert different_key.key != nil
    end
  end
end
