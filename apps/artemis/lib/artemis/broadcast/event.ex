defmodule Artemis.Event do
  @moduledoc """
  Broadcast events that change data
  """

  @broadcast_topic "private:artemis:events"

  @whitelisted_meta_keys [
    "reason",
    "resource_id",
    "resource_type"
  ]

  def get_broadcast_topic, do: @broadcast_topic

  def broadcast(result, event, meta \\ %{}, user)

  def broadcast({:ok, data} = result, event, meta, user) do
    payload = %{
      data: data,
      meta: get_whitelisted_meta(meta),
      user: user
    }

    :ok = ArtemisPubSub.broadcast(@broadcast_topic, event, payload)

    result
  end

  def broadcast({:error, _} = result, _event, _meta, _user) do
    result
  end

  def broadcast(data, event, meta, user) do
    broadcast({:ok, data}, event, meta, user)
  end

  # Helpers

  defp get_whitelisted_meta(meta) when is_list(meta) do
    case Keyword.keyword?(meta) do
      true ->
        meta
        |> Enum.into(%{})
        |> get_whitelisted_meta()

      false ->
        nil
    end
  end

  defp get_whitelisted_meta(meta) when is_map(meta) do
    meta
    |> Artemis.Helpers.keys_to_strings()
    |> Map.take(@whitelisted_meta_keys)
  end

  defp get_whitelisted_meta(_meta), do: nil
end
