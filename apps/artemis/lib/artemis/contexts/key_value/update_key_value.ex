defmodule Artemis.UpdateKeyValue do
  use Artemis.Context

  alias Artemis.KeyValue
  alias Artemis.GetKeyValue
  alias Artemis.Repo

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating key value")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    with_transaction(fn ->
      params = update_params(params)

      id
      |> get_record(user)
      |> update_record(params)
      |> maybe_decode_result()
      |> Event.broadcast("key-value:updated", params, user)
    end)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetKeyValue.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    record
    |> KeyValue.changeset(params)
    |> Repo.update()
  end

  # Helpers - Encoding

  defp update_params(params) do
    params
    |> maybe_encode_field(:key)
    |> maybe_encode_field(:value)
  end

  defp maybe_encode_field(params, field) do
    case Artemis.Helpers.indifferent_get(params, field) do
      nil -> params
      value -> Artemis.Helpers.indifferent_put(params, field, KeyValue.encode(value))
    end
  end

  # Helpers - Decoding

  defp maybe_decode_result({:ok, result}) do
    decoded =
      result
      |> maybe_decode_key()
      |> maybe_decode_value()

    {:ok, decoded}
  end

  defp maybe_decode_result(error), do: error

  defp maybe_decode_key(result) when is_map(result) do
    case Map.get(result, :key) do
      nil -> result
      key -> Map.put(result, :key, KeyValue.decode(key))
    end
  end

  defp maybe_decode_key(result), do: result

  defp maybe_decode_value(result) when is_map(result) do
    case Map.get(result, :value) do
      nil -> result
      value -> Map.put(result, :value, KeyValue.decode(value))
    end
  end

  defp maybe_decode_value(result), do: result
end
