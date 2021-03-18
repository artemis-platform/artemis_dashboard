defmodule Artemis.UpdateKeyValueTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateKeyValue

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:key_value)

      assert_raise Artemis.Context.Error, fn ->
        UpdateKeyValue.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      key_value = insert(:key_value)
      params = %{}

      updated = UpdateKeyValue.call!(key_value, params, Mock.system_user())

      assert updated.key == key_value.key
      assert updated.value == key_value.value
    end

    test "updates a record when passed valid params" do
      key_value = insert(:key_value)
      params = params_for(:key_value)

      assert key_value.key != params.key
      assert key_value.value != params.value

      updated = UpdateKeyValue.call!(key_value, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end

    test "updates a record when passed an id and valid params" do
      key_value = insert(:key_value)
      params = params_for(:key_value)

      assert key_value.key != params.key
      assert key_value.value != params.value

      updated = UpdateKeyValue.call!(key_value.id, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end

    test "updates a record when passed a key and valid params" do
      key_value = insert(:key_value)
      params = params_for(:key_value)

      assert key_value.key != params.key
      assert key_value.value != params.value

      updated = UpdateKeyValue.call!(key_value.key, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:key_value)

      {:error, _} = UpdateKeyValue.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      key_value = insert(:key_value)
      params = %{}

      {:ok, updated} = UpdateKeyValue.call(key_value, params, Mock.system_user())

      assert updated.key == key_value.key
      assert updated.value == key_value.value
    end

    test "updates a record when passed valid params" do
      key_value = insert(:key_value)
      params = params_for(:key_value)

      assert key_value.key != params.key
      assert key_value.value != params.value

      {:ok, updated} = UpdateKeyValue.call(key_value, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end

    test "updates a record when passed an id and valid params" do
      key_value = insert(:key_value)
      params = params_for(:key_value)

      assert key_value.key != params.key
      assert key_value.value != params.value

      {:ok, updated} = UpdateKeyValue.call(key_value.id, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end

    test "updates a record when passed a key and valid binary params" do
      key_value = insert(:key_value)
      params = params_for(:key_value, key: "hello", value: "world")

      assert key_value.key != params.key
      assert key_value.value != params.value

      {:ok, updated} = UpdateKeyValue.call(key_value.key, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end

    test "updates a record when passed a key and valid non-binary params" do
      key_value = insert(:key_value)
      params = params_for(:key_value, key: 'hello', value: %{hello: %{world: true}})

      assert key_value.key != params.key
      assert key_value.value != params.value

      {:ok, updated} = UpdateKeyValue.call(key_value.key, params, Mock.system_user())

      assert updated.key == params.key
      assert updated.value == params.value
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      key_value = insert(:key_value)
      params = params_for(:key_value)

      {:ok, updated} = UpdateKeyValue.call(key_value, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "key-value:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
