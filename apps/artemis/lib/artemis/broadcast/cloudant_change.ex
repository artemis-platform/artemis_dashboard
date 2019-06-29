defmodule Artemis.CloudantChange do
  @moduledoc """
  Broadcast cloudant change records
  """

  defmodule Data do
    defstruct [
      :action,
      :document,
      :id,
      :schema
    ]
  end

  def topic, do: "private:artemis:cloudant-changes"

  def broadcast(%{id: _, schema: _} = data) do
    payload = struct(Data, data)

    :ok = ArtemisPubSub.broadcast(topic(), "cloudant-change", payload)

    data
  end

  def broadcast(data), do: data
end
