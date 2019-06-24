defmodule Artemis.Worker.IBMCloudantChangeListener do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: get_request_timeout() - 5_000,
    log_limit: 500,
    name: :ibm_cloudant_change_listener

  alias Artemis.Drivers.IBMCloudant

  defmodule Data do
    defstruct [
      :connection,
      :last_sequence,
      :schema
    ]
  end

  @hackney_pool :cloudant_change_watcher_pool

  # Callbacks

  @impl true
  def call(data) do
    data = get_data_struct(data)
    cloudant_host = data.schema.get_cloudant_host()
    cloudant_path = data.schema.get_cloudant_path()
    timeout = get_request_timeout()

    ensure_connection_pool_available()

    query_params = [
      feed: "continuous",
      include_docs: true,
      since: data.last_sequence || "now",
      style: "main_only",
      timeout: timeout
    ]

    options = [
      async: :once,
      hackney: [pool: @hackney_pool],
      recv_timeout: timeout,
      stream_to: self(),
      timeout: timeout
    ]

    if Artemis.Helpers.present?(data.connection) do
      :hackney.stop_async(data.connection)
    end

    {:ok, connection} = IBMCloudant.call(%{
      host: cloudant_host,
      method: :get,
      options: options,
      params: query_params,
      path: "#{cloudant_path}/_changes"
    })

    {:ok, struct(data, connection: connection)}
  end

  @impl true
  def handle_info_callback(%HTTPoison.AsyncChunk{chunk: chunk}, state) when chunk == "\n" do
    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncChunk{chunk: chunk}, state) do
    decoded = decode_data(chunk)
    sequence = Map.get(decoded, "seq")
    state = store_last_sequence(state, sequence)

    broadcast_cloudant_change(decoded, state.data.schema)

    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncEnd{}, state) do
    update(async: true)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncHeaders{}, state) do
    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncRedirect{}, state) do
    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncResponse{}, state) do
    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(%HTTPoison.AsyncStatus{}, state) do
    HTTPoison.stream_next(state.data.connection)

    {:noreply, state}
  end

  def handle_info_callback(_, state) do
    {:noreply, state}
  end

  # Helpers

  defp enabled? do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:ibm_cloudant_change_listener)
    |> Keyword.fetch!(:enabled)
  end

  defp get_request_timeout do
    # IBM Cloudant API times out after 60 seconds
    60_000
  end

  defp ensure_connection_pool_available do
    case :hackney_pool.find_pool(@hackney_pool) do
      :undefined -> start_connection_pool()
      _ -> :ok
    end
  end

  defp start_connection_pool do
    options = [
      timeout: get_request_timeout(),
      max_connections: 10
    ]

    :ok = :hackney_pool.start_pool(@hackney_pool, options)
  end

  defp get_data_struct(%Data{} = value), do: value
  defp get_data_struct(map) when is_map(map), do: struct(Data, map)
  defp get_data_struct(_), do: get_initial_data_struct()

  defp get_initial_data_struct() do
    struct(Data, schema: Artemis.SharedJob)
  end

  defp decode_data(data) do
    Jason.decode!(data)
  rescue
    _ -> nil
  end

  defp store_last_sequence(state, value) do
    data = struct(state.data, last_sequence: value)

    Map.put(state, :data, data)
  end

  defp broadcast_cloudant_change(data, schema) do
    id = Map.get(data, "id")
    action = get_action(data)
    document = get_document(data)

    Artemis.CloudantChange.broadcast(%{
      action: action,
      document: document,
      id: id,
      schema: schema
    })
  end

  defp get_action(data) do
    cond  do
      deleted?(data) -> "delete"
      first_revision?(data) -> "create"
      true -> "update"
    end
  end

  defp deleted?(%{"deleted" => _}), do: true
  defp deleted?(_), do: false

  defp first_revision?(%{"doc" => %{"_rev" => rev}}), do: String.starts_with?(rev, "1-")
  defp first_revision?(_), do: false

  defp get_document(data) do
    document = Map.get(data, "doc")

    case Artemis.Helpers.present?(document) do
      true -> Artemis.SharedJob.from_json(document)
      false -> document
    end
  end
end
