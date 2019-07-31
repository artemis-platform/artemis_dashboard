defmodule Artemis.Drivers.IBMCloudant.GetIndexes do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path) do
    IBMCloudant.Request.call(%{
      host: host,
      method: :get,
      path: "#{path}/_index"
    })
  end
end
