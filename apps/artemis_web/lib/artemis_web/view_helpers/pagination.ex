defmodule ArtemisWeb.ViewHelper.Pagination do
  use Phoenix.HTML

  @doc """
  Generates pagination
  """
  def render_pagination(conn, data, options \\ [])

  def render_pagination(conn, %Scrivener.Page{} = data, options) do
    total_pages = Map.get(data, :total_pages, 1)
    args = Keyword.get(options, :args, [])
    params = Keyword.get(options, :params, [])

    query_params =
      conn.query_params
      |> Artemis.Helpers.keys_to_atoms()
      |> Map.delete(:page)
      |> Enum.into([])

    params = Keyword.merge(query_params, params)

    assigns = [
      args: args,
      conn: conn,
      data: data,
      links: [],
      params: params,
      type: "scrivener"
    ]

    case total_pages > 1 do
      true -> Phoenix.View.render(ArtemisWeb.LayoutView, "pagination.html", assigns)
      false -> nil
    end
  end

  def render_pagination(conn, %Artemis.CloudantPage{} = params, _) do
    links =
      []
      |> maybe_add_next_button(conn, params)
      |> maybe_add_previous_button(conn, params)

    assigns = [
      links: links,
      type: "bookmarks"
    ]

    case length(links) > 0 do
      true -> Phoenix.View.render(ArtemisWeb.LayoutView, "pagination.html", assigns)
      false -> nil
    end
  end

  defp maybe_add_next_button(links, conn, %{is_last_page: false, bookmark_next: next}) when not is_nil(next) do
    params = %{
      bookmark: next
    }

    path = get_path_with_query_params(conn, params)
    label = raw("Next Page&nbsp;<i class=\"icon angle right\" style=\"margin-right: 0px;\"></i>")
    link = link(label, to: path, class: "item")

    [link | links]
  end

  defp maybe_add_next_button(links, _, _), do: links

  defp maybe_add_previous_button(links, conn, %{bookmark_previous: previous}) when not is_nil(previous) do
    query_string =
      conn
      |> Map.get(:query_params)
      |> Map.delete("bookmark")
      |> Plug.Conn.Query.encode()

    path = "#{conn.request_path}?#{query_string}"
    label = raw("<i class=\"icon reply all\"></i> First Page")
    link = link(label, to: path, class: "item")

    [link | links]
  end

  defp maybe_add_previous_button(links, _, _), do: links

  @doc """
  Returns the current request path and query params.

  Takes an optional second parameter, a map of query params to be merged with
  existing values.
  """
  def get_path_with_query_params(conn, new_params \\ %{}) do
    new_params = Artemis.Helpers.keys_to_strings(new_params)
    current_params = Artemis.Helpers.keys_to_strings(conn.query_params)
    merged_query_params = Artemis.Helpers.deep_merge(current_params, new_params)

    query_string = Plug.Conn.Query.encode(merged_query_params)
    path = "#{conn.request_path}?#{query_string}"

    path
  end
end
