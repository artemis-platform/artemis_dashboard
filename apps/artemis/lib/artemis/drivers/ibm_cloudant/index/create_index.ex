defmodule Artemis.Drivers.IBMCloudant.CreateIndex do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, params) do
    IBMCloudant.Request.call(%{
      body: Jason.encode!(params),
      host: host,
      method: :post,
      path: "#{path}/_index"
    })
  end
end
