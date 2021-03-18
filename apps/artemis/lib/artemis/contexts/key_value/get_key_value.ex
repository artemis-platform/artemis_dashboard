defmodule Artemis.GetKeyValue do
  use Artemis.Context

  import Ecto.Query

  alias Artemis.KeyValue
  alias Artemis.Repo

  @default_preload []

  def call!(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by!/2)
  end

  def call(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by/2)
  end

  defp get_record(value, options, get_by) when not is_list(value) do
    key =
      case Artemis.Helpers.UUID.uuid?(value) do
        true -> [id: value]
        false -> [key: value]
      end

    get_record(key, options, get_by)
  end

  defp get_record(selectors, options, get_by) do
    KeyValue
    |> select_query(KeyValue, options)
    |> preload(^Keyword.get(options, :preload, @default_preload))
    |> get_by.(encode_selectors(selectors))
    |> maybe_decode_result()
  end

  # Helpers - Encoding

  defp encode_selectors(selectors) do
    selectors
    |> maybe_encode_key()
    |> maybe_encode_value()
  end

  defp maybe_encode_key(selectors) do
    case Keyword.get(selectors, :key) do
      nil -> selectors
      key -> Keyword.put(selectors, :key, KeyValue.encode(key))
    end
  end

  defp maybe_encode_value(selectors) do
    case Keyword.get(selectors, :value) do
      nil -> selectors
      value -> Keyword.put(selectors, :value, KeyValue.encode(value))
    end
  end

  # Helpers - Decoding

  defp maybe_decode_result(result) do
    result
    |> maybe_decode_key()
    |> maybe_decode_value()
  end

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
