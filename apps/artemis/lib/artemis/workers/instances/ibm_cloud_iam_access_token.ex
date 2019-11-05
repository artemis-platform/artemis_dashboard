defmodule Artemis.Worker.IBMCloudIAMAccessToken do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 55 * 60 * 1000,
    name: :ibm_cloud_iam_access_token

  alias Artemis.Drivers.IBMCloudIAM.GetAccessToken

  # Callbacks

  @impl true
  def call(_data, _config) do
    {:ok, get_tokens()}
  end

  # Functions

  def get_token!(key) do
    data = get_data()
    entry = Map.get(data, key)

    case valid?(entry) do
      true -> Map.get(entry, :token)
      false -> update().data[key].token
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

  defp get_tokens() do
    Enum.reduce(get_api_keys(), %{}, fn {key, value}, acc ->
      entry = get_token(value)

      Map.put(acc, key, entry)
    end)
  end

  defp get_token(value) do
    case GetAccessToken.call(value) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  defp get_api_keys() do
    :artemis
    |> Application.fetch_env!(:ibm_cloud)
    |> Keyword.fetch!(:iam_api_keys)
  end

  defp valid?(%{meta: %{expiration: expiration}, token: token}) do
    now = DateTime.to_unix(DateTime.utc_now())
    threshold = expiration - 5 * 60

    now < threshold && Artemis.Helpers.present?(token)
  end

  defp valid?(_), do: false
end
