defmodule Artemis.CreateTagTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateTag

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn () ->
        CreateTag.call!(%{}, Mock.system_user())
      end
    end

    test "creates a tag when passed valid params" do
      params = params_for(:tag)

      tag = CreateTag.call!(params, Mock.system_user())

      assert tag.name == params.name
    end

    test "creates slug from name if not passed as a param" do
      params = params_for(:tag, slug: "passed-slug")

      tag = CreateTag.call!(params, Mock.system_user())

      assert tag.slug == "passed-slug"

      # When slug is not passed

      params = params_for(:tag, name: "Passed Name", slug: nil)

      tag = CreateTag.call!(params, Mock.system_user())

      assert tag.slug == "passed-name"
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateTag.call(%{}, Mock.system_user())

      assert errors_on(changeset).name == ["can't be blank"]
    end

    test "creates a tag when passed valid params" do
      params = params_for(:tag)

      {:ok, tag} = CreateTag.call(params, Mock.system_user())

      assert tag.name == params.name
    end

    test "creates a tag with associations" do
      wiki_page = insert(:wiki_page)
      params = :tag
        |> params_for
        |> Map.put(:wiki_pages, [%{id: wiki_page.id}])

      {:ok, tag} = CreateTag.call(params, Mock.system_user())

      assert tag.name == params.name
      assert hd(tag.wiki_pages).id == wiki_page.id
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, tag} = CreateTag.call(params_for(:tag), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "tag:created",
        payload: %{
          data: ^tag
        }
      }
    end
  end
end
