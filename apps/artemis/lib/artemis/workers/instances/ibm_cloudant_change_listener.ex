defmodule Artemis.Worker.IBMCloudantChangeListener do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: get_request_timeout() - 5_000,
    name: :ibm_cloudant_change_listener

  alias Artemis.Drivers.IBMCloudant

  defmodule Data do
    defstruct [
      :connection,
      :last_sequence,
      :schema
    ]
  end

  # Callbacks

  @impl true
  def call(data, config) do
    data = get_data_struct(data, config)
    cloudant_host = data.schema.get_cloudant_host()
    cloudant_path = data.schema.get_cloudant_path()
    timeout = get_request_timeout()

    query_params = [
      feed: "continuous",
      include_docs: true,
      since: data.last_sequence || "now",
      style: "main_only",
      timeout: timeout
    ]

    if data.connection do
      {:ok, _} = Mint.HTTP.close(data.connection)
    end

    query_string = Plug.Conn.Query.encode(query_params)
    path = "/#{cloudant_path}/_changes?#{query_string}"
    method = "GET"

    {:ok, connection, _request_ref} =
      IBMCloudant.RequestStream.call(%{
        host: cloudant_host,
        method: method,
        path: path
      })

    process_messages_on_interval()

    {:ok, struct(data, connection: connection)}
  end

  def process_messages_on_interval() do
    Process.send_after(self(), :process_messages, 1_000)
  end

  @impl true
  @doc """
  Manually retrieve messages when connection in :passive mode
  """
  def handle_info_callback(:process_messages, state) do
    timeout = 15_000
    payload = Mint.HTTP.recv(state.data.connection, 0, timeout)

    state = process_payload(state, payload)

    process_messages_on_interval()

    {:noreply, state}
  end

  @doc """
  Process messages sent when connection in :active mode
  """
  def handle_info_callback(stream, state) do
    {:noreply, process_stream(state, stream)}
  end

  # Helpers

  defp enabled? do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:ibm_cloudant_change_listener)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp get_request_timeout do
    # IBM Cloudant API times out after 60 seconds
    60_000
  end

  defp get_data_struct(%Data{} = value, _config), do: value
  defp get_data_struct(value, _config) when is_map(value), do: struct(Data, value)
  defp get_data_struct(_, config), do: get_initial_data_struct(config)

  defp get_initial_data_struct(config) do
    schema = Keyword.fetch!(config, :schema)

    struct(Data, schema: schema)
  end

  defp process_stream(state, stream) do
    payload = Mint.HTTP.stream(state.data.connection, stream)

    process_payload(state, payload)
  end

  defp process_payload(state, {:ok, connection, responses}) do
    state = process_responses(state, responses)
    data = struct(state.data, connection: connection)

    Map.put(state, :data, data)
  end

  defp process_payload(state, _), do: state

  defp process_responses(state, responses) do
    Enum.reduce(responses, state, fn response, acc ->
      process_response(acc, response)
    end)
  end

  defp process_response(state, {:data, _reference, chunk}) do
    process_response_chunk(state, chunk)
  end

  defp process_response(state, _), do: state

  defp process_response_chunk(state, chunk) do
    case decode_data(chunk) do
      nil ->
        state

      decoded ->
        sequence = Map.get(decoded, "seq")

        broadcast_cloudant_change(decoded, state.data.schema)

        store_last_sequence(state, sequence)
    end
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
    cond do
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
      true -> Artemis.Job.from_json(document)
      false -> document
    end
  end
end
