defmodule ArtemisWeb.ViewHelper.Search do
  use Phoenix.HTML

  @doc """
  Generates class for search form
  """
  def search_class(conn_or_assigns) do
    case search_present?(conn_or_assigns) do
      true -> "ui search active"
      false -> "ui search"
    end
  end

  @doc """
  Generates search form
  """
  def render_search(conn_or_assigns, options \\ [])

  def render_search(%Plug.Conn{} = conn, options) do
    assigns = %{
      query_params: conn.query_params,
      request_path: conn.request_path
    }

    render_search(assigns, options)
  end

  def render_search(%{query_params: query_params, request_path: request_path}, options) do
    Phoenix.View.render(
      ArtemisWeb.LayoutView,
      "search.html",
      options: options,
      query_params: query_params,
      request_path: request_path
    )
  end

  @doc """
  Diplay search and filter notification
  """
  def render_cloudant_search_and_filter_notification(conn_or_assigns) do
    if search_present?(conn_or_assigns) && filters_present?(conn_or_assigns) do
      body = "Due to Cloudant limitations, search and filters cannot be combined."

      ArtemisWeb.ViewHelper.Notifications.render_notification("error", body: body)
    end
  end

  @doc """
  Diplay search limit notification
  """
  def render_cloudant_search_limit_notification(conn_or_assigns) do
    if search_present?(conn_or_assigns) do
      body = "Cloudant search returns a maximum of 200 results"

      ArtemisWeb.ViewHelper.Notifications.render_notification("info", body: body)
    end
  end

  # Helpers

  defp search_present?(%Plug.Conn{} = conn) do
    search_present?(conn.query_params)
  end

  defp search_present?(%{query_params: query_params}) do
    search_present?(query_params)
  end

  defp search_present?(query_params) when is_map(query_params) do
    query_params
    |> Map.get("query")
    |> Artemis.Helpers.present?()
  end

  defp search_present?(_), do: false

  defp filters_present?(%Plug.Conn{} = conn) do
    filters_present?(conn.query_params)
  end

  defp filters_present?(%{query_params: query_params}) do
    filters_present?(query_params)
  end

  defp filters_present?(query_params) when is_map(query_params) do
    query_params
    |> Map.get("filters")
    |> Artemis.Helpers.present?()
  end

  defp filters_present?(_), do: false
end
