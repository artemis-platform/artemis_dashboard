defmodule Artemis.GetDataCenterTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetDataCenter

  setup do
    data_center = insert(:data_center)

    {:ok, data_center: data_center}
  end

  describe "call" do
    test "returns nil data center not found" do
      invalid_id = 50_000_000

      assert GetDataCenter.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds data center by id", %{data_center: data_center} do
      assert GetDataCenter.call(data_center.id, Mock.system_user()).id == data_center.id
    end

    test "finds record by keyword list", %{data_center: data_center} do
      params = [name: data_center.name, slug: data_center.slug]

      assert GetDataCenter.call(params, Mock.system_user()).id == data_center.id
    end
  end

  describe "call!" do
    test "raises an exception data center not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetDataCenter.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds data center by id", %{data_center: data_center} do
      assert GetDataCenter.call!(data_center.id, Mock.system_user()).id == data_center.id
    end
  end
end
