defmodule Artemis.GetUserRoleTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetUserRole

  setup do
    user_role = insert(:user_role)

    {:ok, user_role: user_role}
  end

  describe "call" do
    test "returns nil user_role not found" do
      invalid_id = 50_000_000

      assert GetUserRole.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds user_role by id", %{user_role: user_role} do
      assert GetUserRole.call(user_role.id, Mock.system_user()).id == user_role.id
    end

    test "finds record by keyword list", %{user_role: user_role} do
      assert GetUserRole.call([role_id: user_role.role_id, user_id: user_role.user_id], Mock.system_user()).id ==
               user_role.id
    end
  end

  describe "call!" do
    test "raises an exception user_role not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetUserRole.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds user_role by id", %{user_role: user_role} do
      assert GetUserRole.call!(user_role.id, Mock.system_user()).id == user_role.id
    end
  end
end
