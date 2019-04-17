defmodule Artemis.DeleteWikiRevisionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.WikiRevision
  alias Artemis.DeleteWikiRevision

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000

      assert_raise Artemis.Context.Error, fn () ->
        DeleteWikiRevision.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:wiki_revision)

      %WikiRevision{} = DeleteWikiRevision.call!(record, Mock.system_user())

      assert Repo.get(WikiRevision, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:wiki_revision)

      %WikiRevision{} = DeleteWikiRevision.call!(record.id, Mock.system_user())

      assert Repo.get(WikiRevision, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50000000

      {:error, _} = DeleteWikiRevision.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:wiki_revision)

      {:ok, _} = DeleteWikiRevision.call(record, Mock.system_user())

      assert Repo.get(WikiRevision, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:wiki_revision)

      {:ok, _} = DeleteWikiRevision.call(record.id, Mock.system_user())

      assert Repo.get(WikiRevision, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, wiki_revision} = DeleteWikiRevision.call(insert(:wiki_revision), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "wiki-revision:deleted",
        payload: %{
          data: ^wiki_revision
        }
      }
    end
  end
end
