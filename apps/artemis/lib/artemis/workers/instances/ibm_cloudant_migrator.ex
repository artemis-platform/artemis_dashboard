defmodule Artemis.Worker.IBMCloudantMigrator do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    interval: 24 * 60 * 60 * 1000,
    name: :ibm_cloudant_migrator

  alias Artemis.Drivers.IBMCloudant

  @moduledoc """
  Runs IBMCloudant.Creator on an interval, ensuring databases and indexes are
  created.
  """

  # Callbacks

  @impl true
  def call(_data, _config), do: IBMCloudant.CreateAll.call()

  # Helpers

  defp enabled?() do
    :artemis
    |> Application.fetch_env!(:actions)
    |> Keyword.fetch!(:ibm_cloudant_migrator)
    |> Keyword.fetch!(:enabled)
    |> String.downcase()
    |> String.equivalent?("true")
  end
end
