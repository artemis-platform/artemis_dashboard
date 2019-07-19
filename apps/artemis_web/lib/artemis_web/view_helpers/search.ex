defmodule ArtemisWeb.ViewHelper.Search do
  use Phoenix.HTML

  @doc """
  Generates class for search form
  """
  def search_class(conn) do
    case search_present?(conn) do
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

  @doc """
  Diplay search limit notification
  """
  def render_cloudant_search_limit_notification(conn) do
    if search_present?(conn) do
      body = "Cloudant search returns a maximum of 200 results"

      ArtemisWeb.ViewHelper.Notifications.render_notification("info", body: body)
    end
  end

  # Helpers

  defp search_present?(conn) do
    conn
    |> Map.get(:query_params, %{})
    |> Map.get("query")
    |> Artemis.Helpers.present?()
  end
end
