defmodule Artemis.ListWikiPagesTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListWikiPages
  alias Artemis.Repo
  alias Artemis.WikiPage

  setup do
    Repo.delete_all(WikiPage)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no wiki pages exist" do
      assert ListWikiPages.call(Mock.system_user()) == []
    end

    test "returns existing wiki page" do
      wiki_page = insert(:wiki_page)

      assert ListWikiPages.call(Mock.system_user()) == [wiki_page]
    end

    test "returns a list of wiki pages" do
      count = 3
      insert_list(count, :wiki_page)

      wiki_pages = ListWikiPages.call(Mock.system_user())

      assert length(wiki_pages) == count
    end
  end

  describe "call - params" do
    setup do
      wiki_page = insert(:wiki_page)

      {:ok, wiki_page: wiki_page}
    end

    test "distinct" do
      Repo.delete_all(WikiPage)

      section1 = "Section 1"
      section2 = "Section 2"

      insert_list(2, :wiki_page, section: section1)
      insert_list(3, :wiki_page, section: section2)

      params = %{
        distinct: "section"
      }

      results = ListWikiPages.call(params, Mock.system_user())
      sections = Enum.map(results, & &1.section)

      assert length(results) == 2
      assert sections == ["Section 1", "Section 2"]
    end

    test "order" do
      insert_list(3, :wiki_page)

      params = %{order: "title"}
      ascending = ListWikiPages.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListWikiPages.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListWikiPages.call(params, Mock.system_user())
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
      insert(:wiki_page, title: "Four Six", slug: "four-six")
      insert(:wiki_page, title: "Four Two", slug: "four-two")
      insert(:wiki_page, title: "Five Six", slug: "five-six")

      user = Mock.system_user()
      wiki_pages = ListWikiPages.call(user)

      assert length(wiki_pages) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      wiki_pages = ListWikiPages.call(params, user)

      assert length(wiki_pages) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      wiki_pages = ListWikiPages.call(params, user)

      assert length(wiki_pages) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      wiki_pages = ListWikiPages.call(params, user)

      assert length(wiki_pages) == 0
    end
  end
end
