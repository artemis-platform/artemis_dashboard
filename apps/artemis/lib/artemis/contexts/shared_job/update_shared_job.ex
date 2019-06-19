defmodule Artemis.UpdateSharedJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetSharedJob
  alias Artemis.SharedJob

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
    path = "#{SharedJob.cloudant_path()}/#{id}"
    query_params = [rev: rev]
    body =
      params
      |> SharedJob.to_json()
      |> Jason.encode!()

    IBMCloudant.call(%{
      body: body,
      method: :put,
      params: query_params,
      url: path
    })
  end

  defp parse_response({:ok, body}), do: body
  defp parse_response({:error, %Ecto.Changeset{} = changeset}), do: {:error, changeset}
  defp parse_response(_), do: {:error, "Error deleting shared job"}
end
