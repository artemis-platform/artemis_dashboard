defmodule ArtemisWeb.ViewHelper.Pagination do
  use Phoenix.HTML

  @doc """
  Generates pagination
  """
  def render_pagination(conn_or_assigns, data, options \\ [])

  def render_pagination(%Plug.Conn{} = conn, data, options) do
    assigns = %{
      conn: conn,
      query_params: conn.query_params,
      request_path: conn.request_path
    }

    render_pagination(assigns, data, options)
  end

  def render_pagination(assigns, %Scrivener.Page{} = data, options) do
    conn_or_socket = Map.get(assigns, :conn_or_socket) || Map.get(assigns, :conn) || Map.get(assigns, :socket)
    query_params = Map.get(assigns, :query_params)
    request_path = Map.get(assigns, :request_path)

    total_pages = Map.get(data, :total_pages, 1)
    args = Keyword.get(options, :args, [])
    params = Keyword.get(options, :params, [])

    query_params =
      query_params
      |> Artemis.Helpers.keys_to_atoms()
      |> Map.delete(:page)
      |> Enum.into([])

    params = Keyword.merge(query_params, params)

    assigns = [
      args: args,
      conn_or_socket: conn_or_socket,
      data: data,
      links: [],
      params: params,
      query_params: query_params,
      request_path: request_path,
      type: "scrivener"
    ]

    case total_pages > 1 do
      true -> Phoenix.View.render(ArtemisWeb.LayoutView, "pagination.html", assigns)
      false -> nil
    end
  end

  def render_pagination(assigns, params, _) do
    query_params = Map.get(assigns, :query_params)
    request_path = Map.get(assigns, :request_path)

    links =
      []
      |> maybe_add_next_button(request_path, query_params, params)
      |> maybe_add_previous_button(request_path, query_params, params)

    assigns = [
      links: links,
      type: "bookmarks"
    ]

    case length(links) > 0 do
      true -> Phoenix.View.render(ArtemisWeb.LayoutView, "pagination.html", assigns)
      false -> nil
    end
  end

  defp maybe_add_next_button(links, request_path, query_params, %{is_last_page: false, bookmark_next: next})
       when not is_nil(next) do
    params = %{
      bookmark: next
    }

    assigns = %{
      query_params: query_params,
      request_path: request_path
    }

    path = get_path_with_query_params(assigns, params)
    label = raw("Next Page&nbsp;<i class=\"icon angle right\" style=\"margin-right: 0px;\"></i>")
    link = link(label, to: path, class: "item")

    [link | links]
  end

  defp maybe_add_next_button(links, _, _, _), do: links

  defp maybe_add_previous_button(links, request_path, query_params, %{bookmark_previous: previous})
       when not is_nil(previous) do
    query_string =
      query_params
      |> Map.delete("bookmark")
      |> Plug.Conn.Query.encode()

    path = "#{request_path}?#{query_string}"
    label = raw("<i class=\"icon reply all\"></i> First Page")
    link = link(label, to: path, class: "item")

    [link | links]
  end

  defp maybe_add_previous_button(links, _, _, _), do: links

  @doc """
  Returns the current request path and query params.

  Takes an optional second parameter, a map of query params to be merged with
  existing values.
  """
  def get_path_with_query_params(conn_or_assigns, new_params \\ %{})

  def get_path_with_query_params(%Plug.Conn{} = conn, new_params) do
    assigns = %{
      conn: conn,
      query_params: conn.query_params,
      request_path: conn.request_path
    }

    get_path_with_query_params(assigns, new_params)
  end

  def get_path_with_query_params(assigns, new_params) do
    query_params = Map.get(assigns, :query_params)
    request_path = Map.get(assigns, :request_path)

    new_params = Artemis.Helpers.keys_to_strings(new_params)
    current_params = Artemis.Helpers.keys_to_strings(query_params)
    merged_query_params = Artemis.Helpers.deep_merge(current_params, new_params)

    query_string = Plug.Conn.Query.encode(merged_query_params)
    path = "#{request_path}?#{query_string}"

    path
  end
end
