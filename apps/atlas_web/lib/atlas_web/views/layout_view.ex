defmodule AtlasWeb.LayoutView do
  use AtlasWeb, :view

  def search_class(conn) do
    query = Map.get(conn.query_params, "query")

    case Atlas.Helpers.present?(query) do
      true -> "ui search active"
      false -> "ui search"
    end
  end
end
