defmodule ArtemisWeb.AsyncRenderLivePrivateState do
  use GenServer

  @moduledoc """
  A helper GenServer for AsyncRenderLive to store private live view state.

  It's primary job is to fetch async data without exposing the async data call
  to the browser client.
  """

  def start_link(options) do
    async_data = Keyword.get(options, :async_data)

    initial_state = %{
      async_data: async_data
    }

    GenServer.start_link(__MODULE__, initial_state)
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:async_data, assigns}, _from, state) do
    {:reply, fetch_async_data(state.async_data, assigns), state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp fetch_async_data(async_data, assigns) do
    cond do
      serialized_function?(async_data) ->
        ArtemisWeb.AsyncRenderLive.deserialize(async_data).(assigns)

      tuple_function?(async_data) ->
        {module, function} = async_data

        Kernel.apply(module, function, [assigns])

      true ->
        async_data
    end
  end

  defp serialized_function?(async_data) do
    is_binary(async_data) && is_function(ArtemisWeb.AsyncRenderLive.deserialize(async_data))
  end

  defp tuple_function?(async_data) do
    is_tuple(async_data) && tuple_size(async_data) == 2
  end
end
