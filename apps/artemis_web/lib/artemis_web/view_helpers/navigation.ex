defmodule ArtemisWeb.ViewHelper.Navigation do
  use Phoenix.HTML

  import ArtemisWeb.Config.Navigation

  @doc """
  Lists all primary navigation items
  """
  def render_primary_navigation_items(conn, user, options \\ []) do
    items =
      case Keyword.get(options, :items) do
        nil -> nav_items_for_current_user(user)
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
  Filter nav items by current users permissions
  """
  def nav_items_for_current_user(nil), do: []

  def nav_items_for_current_user(user) do
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
end
