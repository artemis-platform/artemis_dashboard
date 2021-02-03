defmodule Artemis.CreateKeyValue do
  use Artemis.Context

  alias Artemis.KeyValue
  alias Artemis.Repo

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating key value")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    with_transaction(fn ->
      params = create_params(params)

      params
      |> insert_record
      |> maybe_decode_result()
      |> Event.broadcast("key-value:created", params, user)
    end)
  end

  defp insert_record(params) do
    %KeyValue{}
    |> KeyValue.changeset(params)
    |> Repo.insert()
  end

  # Helpers - Encoding

  defp create_params(params) do
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
