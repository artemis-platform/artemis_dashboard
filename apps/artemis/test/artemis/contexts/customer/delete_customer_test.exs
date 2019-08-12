defmodule Artemis.DeleteCustomerTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Customer
  alias Artemis.DeleteCustomer

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000

      assert_raise Artemis.Context.Error, fn ->
        DeleteCustomer.call!(invalid_id, Mock.system_user())
      end
    end

    test "deletes a record when passed valid params" do
      record = insert(:customer)

      %Customer{} = DeleteCustomer.call!(record, Mock.system_user())

      assert Repo.get(Customer, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:customer)

      %Customer{} = DeleteCustomer.call!(record.id, Mock.system_user())

      assert Repo.get(Customer, record.id) == nil
    end
  end

  describe "call" do
    test "returns an error when record not found" do
      invalid_id = 50_000_000

      {:error, _} = DeleteCustomer.call(invalid_id, Mock.system_user())
    end

    test "deletes a record when passed valid params" do
      record = insert(:customer)

      {:ok, _} = DeleteCustomer.call(record, Mock.system_user())

      assert Repo.get(Customer, record.id) == nil
    end

    test "deletes a record when passed an id and valid params" do
      record = insert(:customer)

      {:ok, _} = DeleteCustomer.call(record.id, Mock.system_user())

      assert Repo.get(Customer, record.id) == nil
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, customer} = DeleteCustomer.call(insert(:customer), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "customer:deleted",
        payload: %{
          data: ^customer
        }
      }
    end
  end
end
