defmodule Artemis.GetSharedJob do
  alias Artemis.Drivers.IBMCloudant
  alias Artemis.SharedJob

	@cloudant_database "jobs"
  # TODO: move to config
	@cloudant_host "b133e32d-f26f-4240-aaff-301c222501d1-bluemix.cloudantnosqldb.appdomain.cloud"

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
    path = "#{@cloudant_host}/#{@cloudant_database}/#{id}"

    IBMCloudant.get(path)
  end

  defp parse_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    SharedJob.from_json(body)
	end

  defp parse_response({:ok, %{body: _body, status_code: status_code}}) when status_code in 400..599 do
		{:error, "Server returned #{status_code}"}
	end

  defp parse_response({:error, _message}) do
		{:error, "Error getting shared job"}
	end
end
