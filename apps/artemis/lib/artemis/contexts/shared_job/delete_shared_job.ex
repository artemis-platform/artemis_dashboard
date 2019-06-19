defmodule Artemis.DeleteSharedJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetSharedJob

	@cloudant_database "jobs"
  # TODO: move to config
	@cloudant_host "b133e32d-f26f-4240-aaff-301c222501d1-bluemix.cloudantnosqldb.appdomain.cloud"

  def call!(id, user) do
    case call(id, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting shared job")
      {:ok, result} -> result
    end
  end

  def call(id, user) do
    id
    |> get_record(user)
    |> delete_record()
    |> parse_response()
    |> Event.broadcast("shared-jobs:deleted", user)
  end

  def get_record(%{id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetSharedJob.call(id, user)

  defp delete_record(%{_id: id, _rev: rev}) do
    path = "#{@cloudant_host}/#{@cloudant_database}/#{id}"
    params = [rev: rev]

    IBMCloudant.delete(path, [], params: params)
  end

  defp parse_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    body
	end

  defp parse_response({:ok, %{status_code: status_code} = request}) when status_code in 400..599 do
    Logger.info("Error deleting shared job: " <> inspect(request))

		{:error, "Server returned #{status_code}"}
	end

  defp parse_response({:error, message}) do
    Logger.info("Error deleting shared job: " <> inspect(message))

		{:error, "Error deleting shared job"}
	end
end
