defmodule Artemis.UpdateTagTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateTag

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000
      params = params_for(:tag)

      assert_raise Artemis.Context.Error, fn () ->
        UpdateTag.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      tag = insert(:tag)
      params = %{}

      updated = UpdateTag.call!(tag, params, Mock.system_user())

      assert updated.name == tag.name
    end

    test "updates a record when passed valid params" do
      tag = insert(:tag)
      params = params_for(:tag)

      updated = UpdateTag.call!(tag, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      tag = insert(:tag)
      params = params_for(:tag)

      updated = UpdateTag.call!(tag.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50000000
      params = params_for(:tag)

      {:error, _} = UpdateTag.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      tag = insert(:tag)
      params = %{}

      {:ok, updated} = UpdateTag.call(tag, params, Mock.system_user())

      assert updated.name == tag.name
    end

    test "updates a record when passed valid params" do
      tag = insert(:tag)
      params = params_for(:tag)

      {:ok, updated} = UpdateTag.call(tag, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      tag = insert(:tag)
      params = params_for(:tag)

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates slug from name if not passed as a param" do
      tag = insert(:tag)
      params = params_for(:tag, slug: "passed-slug")

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert updated.slug == "passed-slug"

      # When slug is not passed

      params = params_for(:tag, name: "Passed Name", slug: nil)

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert updated.slug == "passed-name"
    end
  end

  describe "call - associations" do
    test "adds updatable associations and updates record values" do
      tag = insert(:tag)
      wiki_page = insert(:wiki_page)

      tag = Repo.preload(tag, [:wiki_pages])

      assert tag.wiki_pages == []

      # Add Association

      params = %{
        id: tag.id,
        slug: tag.slug,
        name: "Updated name",
        wiki_pages: [
          %{id: wiki_page.id}
        ]
      }

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert updated.name == "Updated name"
      assert updated.wiki_pages != []
    end

    test "removes associations when explicitly passed an empty value" do
      tag = :tag
        |> insert
        |> with_wiki_page

      tag = Repo.preload(tag, [:wiki_pages])

      assert length(tag.wiki_pages) == 1

      # Keeps existing associations if the association key is not passed

      params = %{
        id: tag.id,
        name: "New Name"
      }

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert length(updated.wiki_pages) == 1

      # Only removes associations when the association key is explicitly passed

      params = %{
        id: tag.id,
        wiki_pages: []
      }

      {:ok, updated} = UpdateTag.call(tag.id, params, Mock.system_user())

      assert length(updated.wiki_pages) == 0
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      tag = insert(:tag)
      params = params_for(:tag)

      {:ok, updated} = UpdateTag.call(tag, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "tag:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
