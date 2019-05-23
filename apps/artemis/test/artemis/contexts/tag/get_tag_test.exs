defmodule Artemis.GetTagTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetTag

  setup do
    tag =
      :tag
      |> insert()
      |> with_wiki_page()

    {:ok, tag: tag}
  end

  describe "call" do
    test "returns nil tag not found" do
      invalid_id = 50_000_000

      assert GetTag.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds tag by id", %{tag: tag} do
      assert GetTag.call(tag.id, Mock.system_user()) == tag
    end

    test "finds tag keyword list", %{tag: tag} do
      assert GetTag.call([name: tag.name, type: tag.type], Mock.system_user()) == tag
    end
  end

  describe "call - options" do
    test "preload", %{tag: tag} do
      tag = GetTag.call(tag.id, Mock.system_user())

      assert !is_list(tag.wiki_pages)
      assert tag.wiki_pages.__struct__ == Ecto.Association.NotLoaded

      options = [
        preload: [:wiki_pages]
      ]

      tag = GetTag.call(tag.id, Mock.system_user(), options)

      assert is_list(tag.wiki_pages)
    end
  end

  describe "call!" do
    test "raises an exception tag not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetTag.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds tag by id", %{tag: tag} do
      assert GetTag.call!(tag.id, Mock.system_user()) == tag
    end
  end
end
