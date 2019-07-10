defmodule Artemis.Drivers.IBMCloudant.GetOrCreateDesignDocument do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, document) do
    case IBMCloudant.GetDesignDocument.call(host, path, document) do
      {:error, %{"error" => "not_found"}} -> IBMCloudant.CreateDesignDocument.call(host, path, document)
      response -> response
    end
  end
end
