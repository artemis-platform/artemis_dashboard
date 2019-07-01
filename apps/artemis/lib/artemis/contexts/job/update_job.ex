defmodule Artemis.UpdateJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetJob
  alias Artemis.Job

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating job")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    params = update_params(params)

    id
    |> get_record(user)
    |> update_record(params)
    |> parse_response()
    |> get_updated_record(user)
    |> Event.broadcast("job:updated", user)
  end

  defp update_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> decode_raw_data_param()
  end

  defp decode_raw_data_param(%{"raw_data" => raw_data} = params) when is_bitstring(raw_data) do
    decoded =
      case Jason.decode(raw_data) do
        {:ok, value} -> value
        _ -> raw_data
      end

    Map.put(params, "raw_data", decoded)
  end

  defp decode_raw_data_param(params), do: params

  defp get_updated_record(%{"ok" => true, "id" => id}, user), do: get_record(id, user)
  defp get_updated_record(error, _), do: error

  defp get_record(%{_id: id}, user), do: get_record(id, user)
  defp get_record(id, user), do: GetJob.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    changeset = Job.changeset(record, params)

    case changeset.valid? do
      false -> Ecto.Changeset.apply_action(changeset, :update)
      true -> update(record, params)
    end
  end

  defp update(%{_id: id, _rev: rev} = record, params) do
    body = get_body(record, params)
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_path()
    query_params = [rev: rev]

    IBMCloudant.Request.call(%{
      body: Jason.encode!(body),
      host: cloudant_host,
      method: :put,
      params: query_params,
      path: "#{cloudant_path}/#{id}"
    })
  end

  # Allow custom payloads by giving `raw_data` value precedence if passed
  defp get_body(_, %{"raw_data" => raw_data}), do: raw_data

  defp get_body(record, params) do
    params
    |> Map.put_new("raw_data", record.raw_data)
    |> Job.to_json()
  end

  defp parse_response({:ok, body}), do: body
  defp parse_response({:error, %Ecto.Changeset{} = changeset}), do: {:error, changeset}
  defp parse_response(_), do: {:error, "Error updating job"}
end
