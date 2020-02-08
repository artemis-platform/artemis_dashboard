defmodule Artemis.DeleteWikiPageTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.WikiPage
  alias Artemis.DeleteWikiPage

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteWikiPage.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:wiki_page)

      %WikiPage{} = DeleteWikiPage.call!(record, Mock.system_user())

      assert Repo.get(WikiPage, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:wiki_page)

      %WikiPage{} = DeleteWikiPage.call!(record.id, Mock.system_user())

      assert Repo.get(WikiPage, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteWikiPage.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:wiki_page)

      {:ok, _} = DeleteWikiPage.call(record, Mock.system_user())

      assert Repo.get(WikiPage, record.id) == nil
    end

    test "deletes associated many to many associations" do
      record = insert(:wiki_page)
      comments = insert_list(3, :comment, resource_type: "WikiPage", resource_id: Integer.to_string(record.id))
      _other = insert_list(2, :comment)

      total_before =
        Comment
        |> Repo.all()
        |> length()

      {:ok, _} = DeleteWikiPage.call(record.id, Mock.system_user())

      assert Repo.get(WikiPage, record.id) == nil

      total_after =
        Comment
        |> Repo.all()
        |> length()

      assert total_after == total_before - 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, wiki_page} = DeleteWikiPage.call(insert(:wiki_page), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "wiki-page:deleted",
        payload: %{
          data: ^wiki_page
        }
      }
    end
  end
end
