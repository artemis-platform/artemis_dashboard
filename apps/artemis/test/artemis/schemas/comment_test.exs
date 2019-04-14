defmodule Artemis.CommentTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.User

  @preload [:user]

  describe "associations - user" do
    setup do
      comment = insert(:comment)

      {:ok, comment: Repo.preload(comment, @preload)}
    end

    test "updating association does not change record", %{comment: comment} do
      user = Repo.get(User, comment.user.id)

      assert user != nil
      assert user.name != "Updated Name"

      params = %{name: "Updated Name"}

      {:ok, user} = user
        |> User.changeset(params)
        |> Repo.update()

      assert user != nil
      assert user.name == "Updated Name"

      assert Repo.get(Comment, comment.id).user_id == user.id
    end

    test "deleting association nilifies record", %{comment: comment} do
      assert Repo.get(User, comment.user.id) != nil

      Repo.delete!(comment.user)

      assert Repo.get(User, comment.user.id) == nil
      assert Repo.get(Comment, comment.id).user_id == nil
    end

    test "deleting record does not remove association", %{comment: comment} do
      assert Repo.get(User, comment.user.id) != nil

      Repo.delete!(comment)

      assert Repo.get(User, comment.user.id) != nil
      assert Repo.get(Comment, comment.id) == nil
    end
  end
end
