defmodule Artemis.CreateUserRoleTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateUserRole

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Postgrex.Error, fn ->
        CreateUserRole.call!(%{}, Mock.system_user())
      end
    end

    test "creates a user_role when passed valid params" do
      params = params_for(:user_role)

      user_role = CreateUserRole.call!(params, Mock.system_user())

      assert user_role.role_id == params.role_id
    end
  end

  describe "call" do
    test "raises an error when params are empty" do
      assert_raise Postgrex.Error, fn ->
        CreateUserRole.call!(%{}, Mock.system_user())
      end
    end

    test "creates a user_role when passed valid params" do
      params = params_for(:user_role)

      {:ok, user_role} = CreateUserRole.call(params, Mock.system_user())

      assert user_role.role_id == params.role_id
      assert user_role.user_id == params.user_id
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, user_role} = CreateUserRole.call(params_for(:user_role), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user-role:created",
        payload: %{
          data: ^user_role
        }
      }
    end
  end
end
