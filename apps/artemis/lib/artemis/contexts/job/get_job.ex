defmodule Artemis.GetJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.Job

  def call!(id, user, options \\ []) do
    case call(id, user, options) do
      nil -> raise(Artemis.Context.Error, "Error getting job")
      response -> response
    end
  end

  def call(id, user, options \\ []) do
    id
    |> get_record(options, user)
    |> parse_response()
  end

  defp get_record(id, _options, _user) do
    cloudant_host = Job.get_cloudant_host()
    cloudant_path = Job.get_cloudant_path()

    IBMCloudant.Request.call(%{
      host: cloudant_host,
      method: :get,
      path: "#{cloudant_path}/#{id}"
    })
  end

  defp parse_response({:ok, body}), do: Job.from_json(body)
  defp parse_response(_), do: nil
end
