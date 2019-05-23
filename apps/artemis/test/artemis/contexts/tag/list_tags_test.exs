defmodule Artemis.ListTagsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListTags
  alias Artemis.Repo
  alias Artemis.Tag

  setup do
    Repo.delete_all(Tag)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no tags exist" do
      assert ListTags.call(Mock.system_user()) == []
    end

    test "returns existing tag" do
      tag = insert(:tag)

      assert ListTags.call(Mock.system_user()) == [tag]
    end

    test "returns a list of tags" do
      count = 3
      insert_list(count, :tag)

      tags = ListTags.call(Mock.system_user())

      assert length(tags) == count
    end
  end

  describe "call - params" do
    setup do
      tag = insert(:tag)

      {:ok, tag: tag}
    end

    test "filters" do
      tag = insert(:tag)
      insert_list(3, :tag)

      params = %{}
      results = ListTags.call(params, Mock.system_user())

      assert length(results) == length(Repo.all(Tag))

      # With wiki page many to many association filter

      wiki_page = insert(:wiki_page, tags: [tag])

      params = %{
        filters: %{
          wiki_page_id: wiki_page.id
        },
        preload: [:wiki_pages]
      }

      results = ListTags.call(params, Mock.system_user())

      assert length(results) == 1
      assert hd(hd(results).wiki_pages).id == wiki_page.id
    end

    test "order" do
      insert_list(3, :tag)

      params = %{order: "name"}
      ascending = ListTags.call(params, Mock.system_user())

      params = %{order: "-name"}
      descending = ListTags.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys =
        ListTags.call(params, Mock.system_user())
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
      insert(:tag, name: "Four Six", type: "four-six")
      insert(:tag, name: "Four Two", type: "four-two")
      insert(:tag, name: "Five Six", type: "five-six")

      user = Mock.system_user()
      tags = ListTags.call(user)

      assert length(tags) == 4

      # Succeeds when given a word part of a larger phrase

      params = %{
        query: "Six"
      }

      tags = ListTags.call(params, user)

      assert length(tags) == 2

      # Succeeds with partial value when it is start of a word

      params = %{
        query: "four-"
      }

      tags = ListTags.call(params, user)

      assert length(tags) == 2

      # Fails with partial value when it is not the start of a word

      params = %{
        query: "our"
      }

      tags = ListTags.call(params, user)

      assert length(tags) == 0
    end
  end
end
