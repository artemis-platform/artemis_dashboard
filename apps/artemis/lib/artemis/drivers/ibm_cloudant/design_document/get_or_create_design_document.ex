defmodule Artemis.Drivers.IBMCloudant.GetOrCreateDesignDocument do
  alias Artemis.Drivers.IBMCloudant

  def call(host, path, document, body \\ %{}) do
    case IBMCloudant.GetDesignDocument.call(host, path, document) do
      {:error, %{"error" => "not_found"}} -> IBMCloudant.CreateDesignDocument.call(host, path, document, body)
      response -> response
    end
  end
end
