defmodule Artemis.CreateCustomerTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateCustomer

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateCustomer.call!(%{}, Mock.system_user())
      end
    end

    test "creates a customer when passed valid params" do
      params = params_for(:customer)

      customer = CreateCustomer.call!(params, Mock.system_user())

      assert customer.name == params.name
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateCustomer.call(%{}, Mock.system_user())

      assert errors_on(changeset).name == ["can't be blank"]
    end

    test "creates a customer when passed valid params" do
      params = params_for(:customer)

      {:ok, customer} = CreateCustomer.call(params, Mock.system_user())

      assert customer.name == params.name
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, customer} = CreateCustomer.call(params_for(:customer), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "customer:created",
        payload: %{
          data: ^customer
        }
      }
    end
  end
end
