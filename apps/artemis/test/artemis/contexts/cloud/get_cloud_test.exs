defmodule Artemis.GetCloudTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetCloud

  setup do
    cloud = insert(:cloud)

    {:ok, cloud: cloud}
  end

  describe "call" do
    test "returns nil cloud not found" do
      invalid_id = 50_000_000

      assert GetCloud.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds cloud by id", %{cloud: cloud} do
      assert GetCloud.call(cloud.id, Mock.system_user()).id == cloud.id
    end

    test "finds record by keyword list", %{cloud: cloud} do
      assert GetCloud.call([name: cloud.name, slug: cloud.slug], Mock.system_user()).id == cloud.id
    end
  end

  describe "call!" do
    test "raises an exception cloud not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetCloud.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds cloud by id", %{cloud: cloud} do
      assert GetCloud.call!(cloud.id, Mock.system_user()).id == cloud.id
    end
  end
end
