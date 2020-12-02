defmodule ArtemisNotify.ViewHelper.Url do
  @doc """
  Prints a full Artemis Web URL for a given path
  """
  def artemis_web_url(raw_path) when is_bitstring(raw_path) do
    domain = artemis_web_domain()
    path = String.trim_leading(raw_path, "/")

    "https://" <> domain <> "/" <> path
  end

  defp artemis_web_domain() do
    :artemis_notify
    |> Application.fetch_env!(:artemis_web_url)
    |> String.trim_leading("http://")
    |> String.trim_leading("https://")
  end
end
