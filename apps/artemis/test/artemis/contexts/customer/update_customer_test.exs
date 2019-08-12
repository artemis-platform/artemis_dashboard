defmodule Artemis.UpdateCustomerTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateCustomer

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:customer)

      assert_raise Artemis.Context.Error, fn ->
        UpdateCustomer.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      customer = insert(:customer)
      params = %{}

      updated = UpdateCustomer.call!(customer, params, Mock.system_user())

      assert updated.name == customer.name
    end

    test "updates a record when passed valid params" do
      customer = insert(:customer)
      params = params_for(:customer)

      updated = UpdateCustomer.call!(customer, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      customer = insert(:customer)
      params = params_for(:customer)

      updated = UpdateCustomer.call!(customer.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:customer)

      {:error, _} = UpdateCustomer.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      customer = insert(:customer)
      params = %{}

      {:ok, updated} = UpdateCustomer.call(customer, params, Mock.system_user())

      assert updated.name == customer.name
    end

    test "updates a record when passed valid params" do
      customer = insert(:customer)
      params = params_for(:customer)

      {:ok, updated} = UpdateCustomer.call(customer, params, Mock.system_user())

      assert updated.name == params.name
    end

    test "updates a record when passed an id and valid params" do
      customer = insert(:customer)
      params = params_for(:customer)

      {:ok, updated} = UpdateCustomer.call(customer.id, params, Mock.system_user())

      assert updated.name == params.name
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      customer = insert(:customer)
      params = params_for(:customer)

      {:ok, updated} = UpdateCustomer.call(customer, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "customer:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
