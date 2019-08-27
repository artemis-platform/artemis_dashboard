defmodule Artemis.Drivers.IBMCloudIAM.GetAccessToken do
  alias Artemis.Drivers.IBMCloudIAM

  def call(api_key) do
    with {:ok, response} <- request_access_token(api_key),
         {:ok, data} <- process_response(response) do
      {:ok, data}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  # Helpers

  defp request_access_token(api_key) do
    params = [
      apikey: api_key,
      grant_type: "urn:ibm:params:oauth:grant-type:apikey"
    ]

    body = {:form, params}
    headers = []
    options = []

    IBMCloudIAM.Request.post("/identity/token", body, headers, options)
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
end
