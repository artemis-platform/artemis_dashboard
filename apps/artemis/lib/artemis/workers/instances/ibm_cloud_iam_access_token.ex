defmodule Artemis.Worker.IBMCloudIAMAccessToken do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 55 * 60 * 1000,
    name: :ibm_cloud_iam_access_token

  alias Artemis.Drivers.IBMCloudIAM

  # Callbacks

  @impl true
  def call(_data, _config) do
    with {:ok, response} <- request_access_token(),
         {:ok, data} <- process_response(response) do
      {:ok, data}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  # Functions

  def get_token!() do
    data = get_data()

    case valid?(data) do
      true -> Map.get(data, :token)
      false -> update().data.token
    end
  end

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:ibm_cloud_iam_access_token)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end

  defp get_api_key() do
    :artemis
    |> Application.fetch_env!(:ibm_cloud)
    |> Keyword.fetch!(:iam_api_key)
  end

  defp request_access_token() do
    params = [
      apikey: get_api_key(),
      grant_type: "urn:ibm:params:oauth:grant-type:apikey"
    ]

    body = {:form, params}
    headers = []
    options = []

    IBMCloudIAM.post("/identity/token", body, headers, options)
  end

  defp process_response(%{body: body, status_code: 200}) do
    data = %{
      token: Map.get(body, "access_token"),
      meta: %{
        access_token: Map.get(body, "access_token"),
        expiration: Map.get(body, "expiration"),
        expires_in: Map.get(body, "expires_in"),
        refresh_token: Map.get(body, "refresh_token"),
        scope: Map.get(body, "scope"),
        token_type: Map.get(body, "token_type")
      }
    }

    {:ok, data}
  end

  defp process_response(%{body: %{"errorCode" => code, "errorMessage" => message}}) do
    {:error, "IBM Cloud IAM API error #{code}: #{message}"}
  end

  defp process_response(_), do: {:error, "Unknown error response from IBM Cloud IAM API"}

  defp valid?(%{meta: %{expiration: expiration}, token: token}) do
    now = DateTime.to_unix(DateTime.utc_now())
    threshold = expiration - 5 * 60

    now < threshold && Artemis.Helpers.present?(token)
  end

  defp valid?(_), do: false
end
