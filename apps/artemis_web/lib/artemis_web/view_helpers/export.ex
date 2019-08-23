defmodule ArtemisWeb.ViewHelper.Export do
  use Phoenix.HTML

  @doc """
  Limit the number of records returned
  """
  def get_export_limit(), do: 10_000

  @doc """
  Render export actions dropdown
  """
  def render_export_actions(conn, options \\ []) do
    assigns = [
      conn: conn,
      options: options
    ]

    Phoenix.View.render(ArtemisWeb.LayoutView, "export.html", assigns)
  end

  @doc """
  Render export current columns action
  """
  def render_export_current_columns_action(conn, _options) do
    path_params = %{
      "page_size" => get_export_limit()
    }

    path = export_path(conn, :csv, path_params)

    link_options = [
      class: "export",
      download: true,
      size: "medium",
      to: path
    ]

    link("Export Current Columns", link_options)
  end

  @doc """
  Render export all columns action
  """
  def render_export_all_columns_action(conn, options) do
    columns =
      options
      |> Keyword.get(:available_columns, [])
      |> Enum.map(&elem(&1, 1))
      |> Enum.sort()

    path_params = %{
      "columns" => columns,
      "page_size" => get_export_limit()
    }

    path = export_path(conn, :csv, path_params)

    link_options = [
      class: "export",
      download: true,
      size: "medium",
      to: path
    ]

    link("Export All Columns", link_options)
  end

  @doc """
  Export path helper
  """
  def export_path(conn, format, params \\ []) do
    additional_params =
      params
      |> Enum.into(%{})
      |> Artemis.Helpers.keys_to_strings()

    query_params =
      conn
      |> Map.get(:query_params, %{})
      |> Map.put("_format", format)
      |> Map.merge(additional_params)

    query_string = Plug.Conn.Query.encode(query_params)

    "#{conn.request_path}?#{query_string}"
  end
end
