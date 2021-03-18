defmodule Artemis.Event do
  @moduledoc """
  Broadcast events that change data
  """

  defmodule Data do
    defstruct [
      :data,
      :meta,
      :type,
      :user
    ]
  end

  @broadcast_topic "private:artemis:events"

  @allowlisted_meta_keys [
    "reason",
    "resource_id",
    "resource_type"
  ]

  @system_events_to_not_broadcast Artemis.Helpers.AppConfig.fetch!(:artemis, :event, :system_events_to_not_broadcast)

  def get_broadcast_topic, do: @broadcast_topic

  def broadcast(result, event, meta \\ %{}, user)

  def broadcast(result, _event, %{broadcast: false}, _user), do: return_tuple(result)

  def broadcast(result, _event, %{"broadcast" => false}, _user), do: return_tuple(result)

  def broadcast({:ok, _data} = result, event, meta, user) do
    case broadcast_event?(event, user) do
      true -> broadcast_event(result, event, meta, user)
      false -> result
    end
  end

  def broadcast({:error, _} = result, _event, _meta, _user) do
    result
  end

  def broadcast(data, event, meta, user) do
    broadcast({:ok, data}, event, meta, user)
  end

  def broadcast_event({:ok, data} = result, event, meta, user) do
    payload = %Data{
      data: data,
      meta: get_allowlisted_meta(meta),
      type: "event",
      user: user
    }

    :ok = ArtemisPubSub.broadcast(@broadcast_topic, event, payload)

    result
  end

  # Helpers

  defp get_allowlisted_meta(meta) when is_list(meta) do
    case Keyword.keyword?(meta) do
      true ->
        meta
        |> Enum.into(%{})
        |> get_allowlisted_meta()

      false ->
        nil
    end
  end

  defp get_allowlisted_meta(meta) when is_map(meta) do
    meta
    |> Artemis.Helpers.keys_to_strings()
    |> Map.take(@allowlisted_meta_keys)
  end

  defp get_allowlisted_meta(_meta), do: nil

  defp return_tuple(response) when is_tuple(response), do: response
  defp return_tuple(response), do: {:ok, response}

  defp broadcast_event?(event, user) do
    ignore? = Enum.member?(@system_events_to_not_broadcast, event) && system_user?(user)

    !ignore?
  end

  defp system_user?(user) when is_map(user) do
    case Artemis.Helpers.indifferent_get(user, :email) do
      nil -> false
      email -> system_user_email_match?(email)
    end
  end

  defp system_user?(_user), do: false

  defp system_user_email_match?(email) do
    system_user = Artemis.Helpers.AppConfig.fetch!(:artemis, :users, :system_user)

    downcase(email) == downcase(system_user.email)
  end

  defp downcase(value) do
    value
    |> Artemis.Helpers.to_string()
    |> String.downcase()
  end
end
