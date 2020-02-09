defmodule Artemis.PagerDutyChange do
  @moduledoc """
  Broadcast PagerDuty changes
  """

  defmodule Data do
    defstruct [
      :data,
      :id,
      :schema,
      :team_id,
      :type
    ]
  end

  def get_topic(schema), do: "private:artemis:pager-duty-changes:#{Artemis.Helpers.dashcase(schema)}"

  def broadcast(data) do
    payload =
      Data
      |> struct(data)
      |> Map.put(:type, "pager-duty-change")

    topic = get_topic(payload.schema)

    :ok = ArtemisPubSub.broadcast(topic, "pager-duty-change", payload)

    data
  end
end
