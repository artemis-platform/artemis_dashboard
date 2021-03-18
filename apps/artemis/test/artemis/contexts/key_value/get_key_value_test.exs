defmodule Artemis.GetKeyValueTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetKeyValue
  alias Artemis.KeyValue

  setup do
    encoded_record = insert(:key_value)

    decoded_record =
      encoded_record
      |> Map.put(:key, KeyValue.decode(encoded_record.key))
      |> Map.put(:value, KeyValue.decode(encoded_record.value))

    {:ok, decoded_record: decoded_record, encoded_record: encoded_record}
  end

  describe "call" do
    test "returns nil key value not found" do
      invalid_key = 50_000_000

      assert GetKeyValue.call(invalid_key, Mock.system_user()) == nil
    end

    test "finds key_value by id", %{decoded_record: decoded_record} do
      assert GetKeyValue.call(decoded_record.id, Mock.system_user()) == decoded_record
    end

    test "finds record by keyword list", %{decoded_record: decoded_record, encoded_record: encoded_record} do
      assert GetKeyValue.call([value: encoded_record.value], Mock.system_user()) == decoded_record
      assert GetKeyValue.call([value: decoded_record.value], Mock.system_user()) == decoded_record
    end

    test "finds record by compound keyword list", %{decoded_record: decoded_record, encoded_record: encoded_record} do
      encoded_keys = [key: encoded_record.key, value: encoded_record.value]
      decoded_keys = [key: decoded_record.key, value: decoded_record.value]

      assert GetKeyValue.call(encoded_keys, Mock.system_user()) == decoded_record
      assert GetKeyValue.call(decoded_keys, Mock.system_user()) == decoded_record
    end
  end

  describe "call!" do
    test "raises an exception key value not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetKeyValue.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds key_value by id", %{decoded_record: decoded_record} do
      assert GetKeyValue.call!(decoded_record.id, Mock.system_user()) == decoded_record
    end
  end
end
