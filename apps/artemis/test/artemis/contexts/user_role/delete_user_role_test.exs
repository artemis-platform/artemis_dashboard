defmodule Artemis.DeleteUserRoleTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UserRole
  alias Artemis.DeleteUserRole

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteUserRole.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:user_role)

      %UserRole{} = DeleteUserRole.call!(record, Mock.system_user())

      assert Repo.get(UserRole, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:user_role)

      %UserRole{} = DeleteUserRole.call!(record.id, Mock.system_user())

      assert Repo.get(UserRole, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteUserRole.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:user_role)

      {:ok, _} = DeleteUserRole.call(record, Mock.system_user())

      assert Repo.get(UserRole, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:user_role)

      {:ok, _} = DeleteUserRole.call(record.id, Mock.system_user())

      assert Repo.get(UserRole, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, user_role} = DeleteUserRole.call(insert(:user_role), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "user-role:deleted",
        payload: %{
          data: ^user_role
        }
      }
    end
  end
end
