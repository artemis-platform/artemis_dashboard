defmodule Artemis.Drivers.IBMCloudant.CreateDesignDocument do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, document, body \\ %{}) do
    {:ok, _} =
      IBMCloudant.Request.call(%{
        body: Jason.encode!(body),
        host: host,
        method: :put,
        path: "#{path}/_design/#{document}"
      })

    IBMCloudant.GetDesignDocument.call(host, path, document)
  end
end
