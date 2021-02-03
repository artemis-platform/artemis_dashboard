defmodule Artemis.CreateOrUpdateKeyValueTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateOrUpdateKeyValue
  alias Artemis.KeyValue

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateOrUpdateKeyValue.call!(%{}, Mock.system_user())
      end
    end

    test "creates a key-value when passed valid params" do
      params = params_for(:key_value)

      key_value = CreateOrUpdateKeyValue.call!(params, Mock.system_user())

      assert key_value.key == params.key
      assert key_value.size == byte_size(params.value)
      assert key_value.value == params.value
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateOrUpdateKeyValue.call(%{}, Mock.system_user())

      assert errors_on(changeset).key == ["can't be blank"]
      assert errors_on(changeset).size == ["can't be blank"]
      assert errors_on(changeset).value == ["can't be blank"]
    end

    test "creates a key-value when passed valid binary params" do
      params = params_for(:key_value, key: "hello", value: "world")

      {:ok, key_value} = CreateOrUpdateKeyValue.call(params, Mock.system_user())

      assert key_value.key == params.key
      assert key_value.size == byte_size(KeyValue.encode(params.value))
      assert key_value.value == params.value
    end

    test "creates a key-value when passed valid non-binary params" do
      params = params_for(:key_value, key: 'hello', value: %{hello: %{world: true}})

      {:ok, key_value} = CreateOrUpdateKeyValue.call(params, Mock.system_user())

      assert key_value.key == params.key
      assert key_value.size == byte_size(KeyValue.encode(params.value))
      assert key_value.value == params.value
    end

    test "updates a key-value when passed valid non-binary params" do
      create_params = params_for(:key_value, key: 'hello', value: %{hello: %{world: true}})

      {:ok, created} = CreateOrUpdateKeyValue.call(create_params, Mock.system_user())

      assert created.key == create_params.key
      assert created.size == byte_size(KeyValue.encode(create_params.value))
      assert created.value == create_params.value

      update_params = params_for(:key_value, key: 'hello', value: %{hello: "world"})

      {:ok, updated} = CreateOrUpdateKeyValue.call(update_params, Mock.system_user())

      assert updated.key == update_params.key
      assert updated.size == byte_size(KeyValue.encode(update_params.value))
      assert updated.value == update_params.value

      assert updated.key == created.key
      assert updated.size != created.size
      assert updated.value != created.value
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, key_value} = CreateOrUpdateKeyValue.call(params_for(:key_value), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "key-value:updated",
        payload: %{
          data: ^key_value
        }
      }
    end
  end
end
