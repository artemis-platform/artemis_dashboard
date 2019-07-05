defmodule ArtemisWeb.ViewHelper.Search do
  use Phoenix.HTML

  @doc """
  Generates class for search form
  """
  def search_class(conn) do
    query = Map.get(conn.query_params, "query")

    case Artemis.Helpers.present?(query) do
      true -> "ui search active"
      false -> "ui search"
    end
  end

  @doc """
  Generates search form
  """
  def render_search(conn, options \\ []) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "search.html", conn: conn, options: options)
  end
end
