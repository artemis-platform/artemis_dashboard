defmodule Artemis.GetWikiPageTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetWikiPage

  setup do
    wiki_page = insert(:wiki_page)

    {:ok, wiki_page: wiki_page}
  end

  describe "call" do
    test "returns nil wiki page not found" do
      invalid_id = 50000000

      assert GetWikiPage.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds wiki page by id", %{wiki_page: wiki_page} do
      assert GetWikiPage.call(wiki_page.id, Mock.system_user()) == wiki_page
    end

    test "finds user keyword list", %{wiki_page: wiki_page} do
      assert GetWikiPage.call([title: wiki_page.title, slug: wiki_page.slug], Mock.system_user()) == wiki_page
    end
  end

  describe "call!" do
    test "raises an exception wiki page not found" do
      invalid_id = 50000000

      assert_raise Ecto.NoResultsError, fn () ->
        GetWikiPage.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds wiki page by id", %{wiki_page: wiki_page} do
      assert GetWikiPage.call!(wiki_page.id, Mock.system_user()) == wiki_page
    end
  end
end
