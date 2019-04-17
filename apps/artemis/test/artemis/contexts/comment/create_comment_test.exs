defmodule Artemis.CreateCommentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateComment

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn () ->
        CreateComment.call!(%{}, Mock.system_user())
      end
    end

    test "creates a comment when passed valid params" do
      params = params_for(:comment)

      comment = CreateComment.call!(params, Mock.system_user())

      assert comment.title == params.title
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateComment.call(%{}, Mock.system_user())

      assert errors_on(changeset).title == ["can't be blank"]
    end

    test "creates a comment when passed valid params" do
      params = params_for(:comment)

      {:ok, comment} = CreateComment.call(params, Mock.system_user())

      assert comment.title == params.title
    end

    test "supports markdown" do
      params = params_for(:comment, body: "# Test")

      {:ok, comment} = CreateComment.call(params, Mock.system_user())

      assert comment.body == params.body
      assert comment.body_html == "<h1>Test</h1>\n"
    end

    test "creates a comment with associations" do
      wiki_page = insert(:wiki_page)
      params = :comment
        |> params_for
        |> Map.put(:wiki_pages, [%{id: wiki_page.id}])

      {:ok, comment} = CreateComment.call(params, Mock.system_user())

      assert comment.title == params.title
      assert hd(comment.wiki_pages).id == wiki_page.id
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, comment} = CreateComment.call(params_for(:comment), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "comment:created",
        payload: %{
          data: ^comment
        }
      }
    end
  end
end
