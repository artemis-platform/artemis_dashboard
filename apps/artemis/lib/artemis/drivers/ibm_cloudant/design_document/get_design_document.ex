defmodule Artemis.Drivers.IBMCloudant.GetDesignDocument do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, document) do
    IBMCloudant.Request.call(%{
      host: host,
      method: :get,
      path: "#{path}/_design/#{document}"
    })
  end
end
