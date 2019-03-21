defmodule Artemis.CreateWikiRevisionTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateWikiRevision

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn () ->
        CreateWikiRevision.call!(%{}, Mock.system_user())
      end
    end

    test "creates a wiki revision when passed valid params" do
      params = params_for(:wiki_revision)

      wiki_revision = CreateWikiRevision.call!(params, Mock.system_user())

      assert wiki_revision.title == params.title
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateWikiRevision.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a wiki revision when passed valid params" do
      params = params_for(:wiki_revision)

      {:ok, wiki_revision} = CreateWikiRevision.call(params, Mock.system_user())

      assert wiki_revision.title == params.title
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, wiki_revision} = CreateWikiRevision.call(params_for(:wiki_revision), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "wiki-revision:created",
        payload: %{
          data: ^wiki_revision
        }
      }
    end
  end
end
