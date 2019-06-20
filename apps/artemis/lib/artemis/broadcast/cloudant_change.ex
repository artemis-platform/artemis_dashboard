defmodule Artemis.CloudantChange do
  @moduledoc """
  Broadcast cloudant change records
  """

  defmodule Data do
    defstruct [
      :action,
      :database,
      :document,
      :host,
      :id
    ]
  end

  @broadcast_topic "private:artemis:cloudant-changes"

  def get_broadcast_topic, do: @broadcast_topic

  def broadcast(%{database: _, host: _, id: _} = data) do
    payload = struct(Data, data)

    :ok = ArtemisPubSub.broadcast(@broadcast_topic, "cloudant-change", payload)

    data
  end

  def broadcast(data), do: data
end
