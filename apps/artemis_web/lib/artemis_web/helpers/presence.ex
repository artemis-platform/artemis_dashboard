defmodule ArtemisWeb.Helpers.Presence do
  alias ArtemisPubSub.Presence

  @topic "artemis-web:presence"

  @doc """
  Create a common presence payload
  """
  def get_presence_topic(), do: @topic

  @doc """
  Create a common presence payload
  """
  def get_presence_payload(path, user) do
    %{
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      path: path,
      session_id: user.session_id,
      user_id: user.id
    }
  end

  @doc """
  Filter presence records by value
  """
  def filter_presences_by(key, value) do
    Enum.filter(list_all_presences(), &(Map.get(&1, key) == value))
  end

  @doc """
  List total number of unique presences
  """
  def total_unique_presences() do
    list_all_presences()
    |> Enum.uniq_by(& &1.user_id)
    |> length()
  end

  @doc """
  List all presence records
  """
  def list_all_presences() do
    @topic
    |> Presence.list()
    |> Enum.map(fn {_user_id, data} ->
      List.first(data[:metas])
    end)
  end
end
