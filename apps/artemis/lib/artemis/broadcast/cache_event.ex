defmodule Artemis.CacheEvent do
  @moduledoc """
  Broadcast cache events
  """

  defmodule Data do
    defstruct [
      :meta,
      :name
    ]
  end

  @broadcast_topic "private:artemis:cache-events"

  def get_broadcast_topic, do: @broadcast_topic

  def broadcast(event, name, meta \\ %{})

  def broadcast(event, name, meta) do
    payload = %Data{
      meta: meta,
      name: name
    }

    ArtemisPubSub.broadcast(@broadcast_topic, event, payload)
  end
end
