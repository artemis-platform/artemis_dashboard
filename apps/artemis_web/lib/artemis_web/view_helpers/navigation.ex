defmodule ArtemisWeb.ViewHelper.Navigation do
  use Phoenix.HTML

  import ArtemisWeb.Config.Navigation
  import ArtemisWeb.Guardian.Helpers

  @doc """
  Lists all primary navigation items
  """
  def render_primary_navigation_items(conn, user, options \\ []) do
    items =
      case Keyword.get(options, :items) do
        nil -> primary_nav_items_for_current_user(user)
        items -> items
      end

    sections =
      Enum.map(items, fn {section, items} ->
        links =
          Enum.map(items, fn item ->
            label = Keyword.get(item, :label)
            path = Keyword.get(item, :path)

            content_tag(:li) do
              link(label, to: path.(conn))
            end
          end)

        content_tag(:article) do
          [
            content_tag(:h5, section),
            content_tag(:ul, links)
          ]
        end
      end)

    content_tag(:nav, class: "primary-navigation-items") do
      sections
    end
  end

  @doc """
  Determine if the current user's permissions result in at least one primary nav entry
  """
  def render_primary_nav_section?(nav_items, keys) do
    allowed_keys = Keyword.keys(nav_items)

    Enum.any?(keys, fn key ->
      Enum.member?(allowed_keys, String.to_atom(key))
    end)
  end

  @doc """
  Render the primary nav based on current users permissions
  """
  def render_primary_nav_section(conn, user, nav_items, keys) do
    requested_keys = Enum.map(keys, &String.to_atom/1)
    allowed_keys = Keyword.keys(nav_items)
    section_keys = Enum.filter(requested_keys, &Enum.member?(allowed_keys, &1))

    filtered =
      section_keys
      |> Enum.reduce([], fn section_key, acc ->
        case Keyword.get(nav_items, section_key) do
          nil -> acc
          nav_item -> [{section_key, nav_item} | acc]
        end
      end)
      |> Enum.reverse()

    render_primary_navigation_items(conn, user, items: filtered)
  end

  @doc """
  Filter primary nav items by current users permissions
  """
  def primary_nav_items_for_current_user(nil), do: []

  def primary_nav_items_for_current_user(user) do
    Enum.reduce(get_nav_items(), [], fn {section, potential_items}, acc ->
      verified_items =
        Enum.filter(potential_items, fn item ->
          verify = Keyword.get(item, :verify)

          verify.(user)
        end)

      case verified_items == [] do
        true -> acc
        false -> [{section, verified_items} | acc]
      end
    end)
  end

  @doc """
  Lists all secondary navigation
  """
  def render_secondary_navigation(conn_or_assigns, user, items)

  def render_secondary_navigation(%Plug.Conn{} = conn, user, items) do
    assigns = %{
      conn: conn,
      query_params: conn.query_params,
      request_path: conn.request_path
    }

    render_secondary_navigation(assigns, user, items)
  end

  def render_secondary_navigation(assigns, user, items) do
    conn_or_socket = assigns[:conn] || assigns[:socket] || assigns[:conn_or_socket]

    verified_items =
      Enum.filter(items, fn item ->
        verify = Keyword.get(item, :verify)

        verify.(user)
      end)

    request_path =
      assigns
      |> Map.get(:request_path)
      |> Kernel.||(Map.get(conn_or_socket, :request_path))
      |> String.trim()
      |> String.trim_trailing("/")

    entries =
      Enum.map(verified_items, fn item ->
        label = Keyword.get(item, :label)
        path = Keyword.get(item, :path)
        path_match_type = Keyword.get(item, :path_match_type)
        to = path.(conn_or_socket)

        active? =
          case path_match_type do
            :starts_with -> String.starts_with?(request_path, to)
            _ -> to == request_path
          end

        class = if active?, do: "selected", else: nil

        content_tag(:li) do
          link(label, class: class, to: to)
        end
      end)

    icon =
      content_tag(:li, class: "icon") do
        content_tag(:i, class: "bars icon") do
          nil
        end
      end

    content_tag(:nav, class: "secondary-navigation-items") do
      content_tag(:ul) do
        [icon | entries]
      end
    end
  end

  @doc """
  Render secondary navigation comment label
  """
  def render_secondary_navigation_live_comment_count_label(%Plug.Conn{} = conn, resource_type, resource_id) do
    assigns = %{
      user: current_user(conn)
    }

    render_secondary_navigation_live_comment_count_label(assigns, resource_type, resource_id)
  end

  def render_secondary_navigation_live_comment_count_label(assigns, resource_type, resource_id) do
    conn_or_socket = assigns[:conn] || assigns[:socket] || assigns[:conn_or_socket]

    session = %{
      "resource_id" => resource_id,
      "resource_type" => resource_type,
      "user" => assigns[:user]
    }

    Phoenix.LiveView.Helpers.live_render(conn_or_socket, ArtemisWeb.CommentCountLabelLive, session: session)
  end
end
