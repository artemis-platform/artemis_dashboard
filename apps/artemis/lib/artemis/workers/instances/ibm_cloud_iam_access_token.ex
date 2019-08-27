defmodule Artemis.Worker.IBMCloudIAMAccessToken do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 55 * 60 * 1000,
    name: :ibm_cloud_iam_access_token

  alias Artemis.Drivers.IBMCloudIAM.GetAccessToken

  # Callbacks

  @impl true
  def call(_data, _config) do
    GetAccessToken.call(get_api_key())
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

  defp valid?(%{meta: %{expiration: expiration}, token: token}) do
    now = DateTime.to_unix(DateTime.utc_now())
    threshold = expiration - 5 * 60

    now < threshold && Artemis.Helpers.present?(token)
  end

  defp valid?(_), do: false
end
