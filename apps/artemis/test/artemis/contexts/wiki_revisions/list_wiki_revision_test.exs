defmodule Artemis.ListWikiRevisionsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListWikiRevisions
  alias Artemis.Repo
  alias Artemis.WikiRevision

  setup do
    Repo.delete_all(WikiRevision)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no wiki revisions exist" do
      assert ListWikiRevisions.call(Mock.system_user()) == []
    end

    test "returns existing wiki revision" do
      wiki_revision = insert(:wiki_revision)

      results = ListWikiRevisions.call(Mock.system_user())

      assert hd(results).id  == wiki_revision.id
    end

    test "returns a list of wiki revisions" do
      count = 3
      insert_list(count, :wiki_revision)

      wiki_revisions = ListWikiRevisions.call(Mock.system_user())

      assert length(wiki_revisions) == count
    end
  end

  describe "call - params" do
    setup do
      wiki_revision = insert(:wiki_revision)

      {:ok, wiki_revision: wiki_revision}
    end

    test "filters" do
      wiki_page = insert(:wiki_page)

      insert_list(2, :wiki_revision, wiki_page: wiki_page)
      insert_list(3, :wiki_revision)

      params = %{}
      results = ListWikiRevisions.call(params, Mock.system_user())

      assert length(results) > 2

      params = %{
        filters: %{
          wiki_page_id: wiki_page.id
        }
      }
      results = ListWikiRevisions.call(params, Mock.system_user())

      assert length(results) == 2
    end

    test "order" do
      insert_list(3, :wiki_revision)

      params = %{order: "title"}
      ascending = ListWikiRevisions.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListWikiRevisions.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys = ListWikiRevisions.call(params, Mock.system_user())
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
  end
end
