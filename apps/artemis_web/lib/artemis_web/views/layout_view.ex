defmodule ArtemisWeb.LayoutView do
  use ArtemisWeb, :view

  def search_class(conn) do
    query = Map.get(conn.query_params, "query")

    case Artemis.Helpers.present?(query) do
      true -> "ui search active"
      false -> "ui search"
    end
  end
end
