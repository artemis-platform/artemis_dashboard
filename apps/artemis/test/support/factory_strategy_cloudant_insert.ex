defmodule Artemis.FactoryStrategy.CloudantInsert do
  use ExMachina.Strategy, function_name: :cloudant_insert

  alias Artemis.Drivers.IBMCloudant

  def handle_cloudant_insert(%{__struct__: schema} = struct, _options) do
    host = schema.get_cloudant_host()
    path = schema.get_cloudant_path()

    as_map =
      struct
      |> Map.from_struct()
      |> Map.delete(:_id)
      |> Map.delete(:_rev)

    {:ok, response} =
      IBMCloudant.Request.call(%{
        body: Jason.encode!(as_map),
        host: host,
        method: :post,
        path: path
      })

    schema
    |> struct(as_map)
    |> Map.put(:_id, response["id"])
    |> Map.put(:_rev, response["rev"])
  end
end
