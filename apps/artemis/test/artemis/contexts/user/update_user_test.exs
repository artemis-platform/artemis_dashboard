defmodule Artemis.UpdateUserTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateUser

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:user)

      assert_raise Artemis.Context.Error, fn ->
        UpdateUser.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      user = insert(:user)
      params = %{}

      updated = UpdateUser.call!(user, params, Mock.system_user())

      assert updated.name == user.name
    end

    test "updates a record when passed valid params" do
      user = insert(:user)
      params = params_for(:user)

      updated = UpdateUser.call!(user, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      user = insert(:user)
      params = params_for(:user)

      updated = UpdateUser.call!(user.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:user)

      {:error, _} = UpdateUser.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      user = insert(:user)
      params = %{}

      {:ok, updated} = UpdateUser.call(user, params, Mock.system_user())

      assert updated.name == user.name
    end

    test "updates a record when passed valid params" do
      user = insert(:user)
      params = params_for(:user)

      {:ok, updated} = UpdateUser.call(user, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      user = insert(:user)
      params = params_for(:user)

      {:ok, updated} = UpdateUser.call(user.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call - associations" do
    test "adds updatable associations and updates record values" do
      user = insert(:user)
      role = insert(:role)

      # Associations not updatable through User
      insert(:wiki_page, user: user)
      insert(:wiki_revision, user: user)

      user = Repo.preload(user, [:user_roles, :wiki_pages, :wiki_revisions])

      assert user.user_roles == []
      assert user.wiki_pages != []
      assert user.wiki_revisions != []

      # Add Association

      params = %{
        id: user.id,
        email: user.email,
        name: "Updated Name",
        user_roles: [
          %{role_id: role.id}
        ],
        wiki_pages: [],
        wiki_revisions: []
      }

      {:ok, updated} = UpdateUser.call(user.id, params, Mock.system_user())

      assert updated.name == "Updated Name"
      assert updated.user_roles != []
      assert updated.wiki_pages != []
      assert updated.wiki_revisions != []
    end

    test "removes associations when explicitly passed an empty value" do
      user =
        :user
        |> insert
        |> with_user_roles

      user = Repo.preload(user, [:user_roles])

      assert length(user.user_roles) == 3

      # Keeps existing associations if the association key is not passed

      params = %{
        id: user.id,
        name: "New Name"
      }

      {:ok, updated} = UpdateUser.call(user.id, params, Mock.system_user())

      assert length(updated.user_roles) == 3

      # Only removes associations when the association key is explicitly passed

      params = %{
        id: user.id,
        user_roles: []
      }

      {:ok, updated} = UpdateUser.call(user.id, params, Mock.system_user())

      assert length(updated.user_roles) == 0
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      user = insert(:user)
      params = params_for(:user)

      {:ok, updated} = UpdateUser.call(user, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
