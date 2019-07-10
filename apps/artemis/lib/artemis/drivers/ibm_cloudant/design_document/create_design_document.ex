defmodule Artemis.Drivers.IBMCloudant.CreateDesignDocument do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, document) do
    {:ok, _} =
      IBMCloudant.Request.call(%{
        body: "{}",
        host: host,
        method: :put,
        path: "#{path}/_design/#{document}"
      })

    IBMCloudant.GetDesignDocument.call(host, path, document)
  end
end
