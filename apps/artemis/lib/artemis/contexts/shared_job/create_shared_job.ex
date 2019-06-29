defmodule Artemis.CreateSharedJob do
  use Artemis.Context

  alias Artemis.Drivers.IBMCloudant
  alias Artemis.GetSharedJob
  alias Artemis.SharedJob

  @moduledoc """
  Creates a new Shared Job document in IBM Cloudant.

  See `Artemis.Context.Cloudant` for details.
  """

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating shared job")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    params = create_params(params)

    params
    |> insert_record()
    |> parse_response()
    |> get_record(user)
    |> Event.broadcast("shared-job:created", user)
  end

  defp create_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> Map.delete("_rev")
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

  defp insert_record(params) do
    changeset = SharedJob.changeset(%SharedJob{}, params)

    case changeset.valid? do
      false -> Ecto.Changeset.apply_action(changeset, :insert)
      true -> insert(params)
    end
  end

  defp insert(params) do
    body = get_body(params)
    cloudant_host = SharedJob.get_cloudant_host()
    cloudant_path = SharedJob.get_cloudant_path()

    IBMCloudant.Request.call(%{
      body: Jason.encode!(body),
      host: cloudant_host,
      method: :post,
      path: cloudant_path
    })
  end

  # Allow custom payloads by giving `raw_data` value precedence if passed
  defp get_body(%{"raw_data" => raw_data}), do: raw_data
  defp get_body(params), do: SharedJob.to_json(params)

  defp parse_response({:ok, body}), do: body
  defp parse_response({:error, %Ecto.Changeset{} = changeset}), do: {:error, changeset}
  defp parse_response(_), do: {:error, "Error creating shared job"}

  defp get_record(%{"ok" => true, "id" => id}, user), do: GetSharedJob.call(id, user)
  defp get_record(error, _), do: error
end
