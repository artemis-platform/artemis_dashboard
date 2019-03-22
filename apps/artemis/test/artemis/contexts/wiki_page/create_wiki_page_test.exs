defmodule Artemis.CreateWikiPageTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateWikiPage

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn () ->
        CreateWikiPage.call!(%{}, Mock.system_user())
      end
    end

    test "creates a wiki page when passed valid params" do
      params = params_for(:wiki_page)

      wiki_page = CreateWikiPage.call!(params, Mock.system_user())

      assert wiki_page.title == params.title
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateWikiPage.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a wiki page when passed valid params" do
      params = params_for(:wiki_page)

      {:ok, wiki_page} = CreateWikiPage.call(params, Mock.system_user())

      assert wiki_page.title == params.title
    end
  end

  describe "associations - wiki revisions" do
    test "creates an associated wiki revision" do
      params = params_for(:wiki_page)

      {:ok, wiki_page} = CreateWikiPage.call(params, Mock.system_user())

      wiki_page = Repo.preload(wiki_page, [:wiki_revisions])

      assert wiki_page.wiki_revisions != []

      assert hd(wiki_page.wiki_revisions).title == wiki_page.title
      assert hd(wiki_page.wiki_revisions).wiki_page_id == wiki_page.id
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, wiki_page} = CreateWikiPage.call(params_for(:wiki_page), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "wiki-page:created",
        payload: %{
          data: ^wiki_page
        }
      }
    end
  end
end
