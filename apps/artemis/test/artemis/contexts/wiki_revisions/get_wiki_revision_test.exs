defmodule Artemis.GetWikiRevisionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetWikiRevision

  setup do
    wiki_revision = insert(:wiki_revision)

    {:ok, wiki_revision: wiki_revision}
  end

  describe "call" do
    test "returns nil wiki revision not found" do
      invalid_id = 50_000_000

      assert GetWikiRevision.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds wiki revision by id", %{wiki_revision: wiki_revision} do
      assert GetWikiRevision.call(wiki_revision.id, Mock.system_user()).id == wiki_revision.id
    end

    test "finds user keyword list", %{wiki_revision: wiki_revision} do
      assert GetWikiRevision.call([title: wiki_revision.title, slug: wiki_revision.slug], Mock.system_user()).id ==
               wiki_revision.id
    end
  end

  describe "call!" do
    test "raises an exception wiki revision not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetWikiRevision.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds wiki revision by id", %{wiki_revision: wiki_revision} do
      assert GetWikiRevision.call!(wiki_revision.id, Mock.system_user()).id == wiki_revision.id
    end
  end
end
