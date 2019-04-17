defmodule Artemis.UpdateWikiPageTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateWikiPage
  alias Artemis.WikiPage

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000
      params = params_for(:wiki_page)

      assert_raise Artemis.Context.Error, fn () ->
        UpdateWikiPage.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      wiki_page = insert(:wiki_page)
      params = %{}

      updated = UpdateWikiPage.call!(wiki_page, params, Mock.system_user())

      assert updated.title == wiki_page.title
    end

    test "updates a record when passed valid params" do
      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page)

      updated = UpdateWikiPage.call!(wiki_page, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page)

      updated = UpdateWikiPage.call!(wiki_page.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50000000
      params = params_for(:wiki_page)

      {:error, _} = UpdateWikiPage.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      wiki_page = insert(:wiki_page)
      params = %{}

      {:ok, updated} = UpdateWikiPage.call(wiki_page, params, Mock.system_user())

      assert updated.title == wiki_page.title
    end

    test "updates a record when passed valid params" do
      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page)

      {:ok, updated} = UpdateWikiPage.call(wiki_page, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page)

      {:ok, updated} = UpdateWikiPage.call(wiki_page.id, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "supports markdown" do
      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page, body: "# Test")

      {:ok, updated} = UpdateWikiPage.call(wiki_page.id, params, Mock.system_user())

      assert updated.body == params.body
      assert updated.body_html == "<h1>Test</h1>\n"
    end
  end

  describe "associations - wiki revisions" do
    test "creates an associated wiki revision" do
      params = params_for(:wiki_page)
      wiki_page = :wiki_page
        |> insert()
        |> Repo.preload([:wiki_revisions])

      assert wiki_page.wiki_revisions == []

      {:ok, wiki_page} = UpdateWikiPage.call(wiki_page, params, Mock.system_user())

      wiki_page = WikiPage
        |> preload([:wiki_revisions])
        |> Repo.get(wiki_page.id)

      assert length(wiki_page.wiki_revisions) == 1

      assert hd(wiki_page.wiki_revisions).title == wiki_page.title
      assert hd(wiki_page.wiki_revisions).wiki_page_id == wiki_page.id

      # Second Update

      {:ok, wiki_page} = UpdateWikiPage.call(wiki_page, params, Mock.system_user())

      wiki_page = WikiPage
        |> preload([:wiki_revisions])
        |> Repo.get(wiki_page.id)

      assert wiki_page.wiki_revisions != []
      assert length(wiki_page.wiki_revisions) == 2
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      wiki_page = insert(:wiki_page)
      params = params_for(:wiki_page)

      {:ok, updated} = UpdateWikiPage.call(wiki_page, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "wiki-page:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
