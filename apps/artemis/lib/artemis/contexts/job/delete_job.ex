defmodule Artemis.DeleteJob do
  use Artemis.Context

  alias Artemis.DeleteManyAssociatedComments
  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetJob
  alias Artemis.Job

  def call!(id, params \\ %{}, user) do
    case call(id, params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error deleting job")
      {:ok, result} -> result
    end
  end

  def call(id, params \\ %{}, user) do
    id
    |> get_record(user)
    |> delete_record()
    |> delete_associated_comments(id, user)
    |> parse_response()
    |> Event.broadcast("job:deleted", params, user)
  end

  def get_record(%{_id: id}, user), do: get_record(id, user)
  def get_record(id, user), do: GetJob.call(id, user)

  def delete_associated_comments(record, resource_id, user) do
    {:ok, _} = DeleteManyAssociatedComments.call("Job", resource_id, user)

    record
  rescue
    _ -> record
  end

  defp delete_record(nil), do: {:error, "Record not found"}

  defp delete_record(%{_id: id, _rev: rev}) do
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_path()
    query_params = [rev: rev]

    IBMCloudant.Request.call(%{
      host: cloudant_host,
      method: :delete,
      params: query_params,
      path: "#{cloudant_path}/#{id}"
    })
  end

  defp parse_response({:ok, body}), do: body
  defp parse_response(_), do: {:error, "Error deleting job"}
end
