defmodule Artemis.DeleteTagTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Tag
  alias Artemis.DeleteTag

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000

      assert_raise Artemis.Context.Error, fn () ->
        DeleteTag.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:tag)

      %Tag{} = DeleteTag.call!(record, Mock.system_user())

      assert Repo.get(Tag, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:tag)

      %Tag{} = DeleteTag.call!(record.id, Mock.system_user())

      assert Repo.get(Tag, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50000000

      {:error, _} = DeleteTag.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:tag)

      {:ok, _} = DeleteTag.call(record, Mock.system_user())

      assert Repo.get(Tag, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:tag)

      {:ok, _} = DeleteTag.call(record.id, Mock.system_user())

      assert Repo.get(Tag, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, tag} = DeleteTag.call(insert(:tag), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "tag:deleted",
        payload: %{
          data: ^tag
        }
      }
    end
  end
end
