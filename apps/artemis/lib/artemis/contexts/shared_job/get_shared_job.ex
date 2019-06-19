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
    path = "#{SharedJob.cloudant_path()}/#{id}"

    IBMCloudant.call(%{
      method: :get,
      url: path
    })
  end

  defp parse_response({:ok, body}), do: SharedJob.from_json(body)
  defp parse_response(_), do: {:error, "Error getting shared job"}
end
