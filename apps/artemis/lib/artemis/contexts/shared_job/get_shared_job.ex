defmodule Artemis.GetSharedJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.SharedJob

  def call!(id, user, options \\ []) do
    case call(id, user, options) do
      {:error, _} -> raise(Artemis.Context.Error, "Error getting shared job")
      response -> response
    end
  end

  def call(id, user, options \\ []) do
    id
    |> get_record(options, user)
    |> parse_response()
  end

  defp get_record(id, _options, _user) do
    cloudant_host = SharedJob.get_cloudant_host()
    cloudant_path = SharedJob.get_cloudant_path()

    IBMCloudant.call(%{
      host: cloudant_host,
      method: :get,
      path: "#{cloudant_path}/#{id}"
    })
  end

  defp parse_response({:ok, body}), do: SharedJob.from_json(body)
  defp parse_response(_), do: {:error, "Error getting shared job"}
end
