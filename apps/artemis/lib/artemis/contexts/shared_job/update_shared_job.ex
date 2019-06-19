defmodule Artemis.UpdateSharedJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetSharedJob
  alias Artemis.SharedJob

  @cloudant_database "jobs"
  # TODO: move to config
  @cloudant_host "b133e32d-f26f-4240-aaff-301c222501d1-bluemix.cloudantnosqldb.appdomain.cloud"

  def call!(id, params, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error updating shared job")
      {:ok, result} -> result
    end
  end

  def call(id, params, user) do
    id
    |> get_record(user)
    |> update_record(params)
    |> parse_response()
    |> get_updated_record(user)
    |> Event.broadcast("shared-job:updated", user)
  end

  defp get_updated_record(%{"ok" => true, "id" => id}, user), do: get_record(id, user)
  defp get_updated_record(error, _), do: error

  defp get_record(%{id: id}, user), do: get_record(id, user)
  defp get_record(id, user), do: GetSharedJob.call(id, user)

  defp update_record(nil, _params), do: {:error, "Record not found"}

  defp update_record(record, params) do
    decoded_raw_data = try_to_decode_raw_data(params)
    params = Map.put(params, "raw_data", decoded_raw_data)
    changeset = SharedJob.changeset(record, params)

    case changeset.valid? do
      false -> Ecto.Changeset.apply_action(changeset, :update)
      true -> update(record, params)
    end
  end

  # When invalid, rescue and return the original value so the changeset can
  # generate a user-friendly error
  defp try_to_decode_raw_data(%{"raw_data" => raw_data}) do
    Jason.decode!(raw_data)
  rescue
    _ -> raw_data
  end

  defp update(%{_id: id, _rev: rev}, params) do
    path = "#{@cloudant_host}/#{@cloudant_database}/#{id}"
    query_params = [rev: rev]

    body =
      params
      |> SharedJob.to_json()
      |> Jason.encode!()

    IBMCloudant.put(path, body, [], params: query_params)
  end

  defp parse_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    body
  end

  defp parse_response({:ok, %{status_code: status_code} = response}) when status_code in 400..599 do
    Logger.info("Error deleting shared job: " <> inspect(response))

    {:error, "Server returned #{status_code}"}
  end

  defp parse_response({:error, %Ecto.Changeset{} = changeset}) do
    {:error, changeset}
  end

  defp parse_response({:error, message}) do
    Logger.info("Error deleting shared job: " <> inspect(message))

    {:error, "Error deleting shared job"}
  end
end
