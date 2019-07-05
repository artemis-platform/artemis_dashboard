defmodule ArtemisWeb.ViewHelper.Layout do
  use Phoenix.HTML

  import ArtemisWeb.ViewData.Layout

  @moduledoc """
  Convenience functions for common layout elements
  """

  @doc """
  Returns existing query params as a Keyword list
  """
  def current_query_params(conn) do
    Enum.into(conn.query_params, [])
  end

  @doc """
  Generates an action tag.

  Type of tag is determined by the `method`:

    GET: Anchor
    POST / PUT / PATCH / DELETE: Button (with CSRF token)

  Unless specified, the `method` value defaults to `GET`.

  Custom options:

    :color <String>
    :size <String>

  All other options are passed directly to the `Phoenix.HTML` function.
  """
  def action(label, options \\ []) do
    color = Keyword.get(options, :color, "basic")
    size = Keyword.get(options, :size, "small")
    method = Keyword.get(options, :method, "get")
    live? = Keyword.get(options, :live, false)

    tag_options =
      options
      |> Enum.into(%{})
      |> Map.put(:class, "button ui #{size} #{color}")
      |> Enum.into([])

    cond do
      method == "get" && live? -> Phoenix.LiveView.live_link(label, tag_options)
      method == "get" -> link(label, tag_options)
      true -> button(label, tag_options)
    end
  end

  @doc """
  Renders a filter button for setting query params in the URL
  """
  def filter_button(conn, label, values) do
    filter_params =
      values
      |> Enum.into(%{})
      |> Artemis.Helpers.keys_to_strings()

    new_query_params = %{"filters" => filter_params}
    merged_query_params = Artemis.Helpers.deep_merge(conn.query_params, new_query_params)
    query_string = Plug.Conn.Query.encode(merged_query_params)
    path = "#{conn.request_path}?#{query_string}"

    active? =
      case conn.query_params["filters"] != nil do
        true -> MapSet.subset?(MapSet.new(new_query_params["filters"]), MapSet.new(conn.query_params["filters"]))
        false -> false
      end

    class =
      case active? do
        true -> "ui basic button blue"
        false -> "ui basic button"
      end

    options = [
      class: class,
      onclick: "location.href='#{path}'",
      type: "button"
    ]

    content_tag(:button, label, options)
  end

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
  Generates primary nav from nav items
  """
  def render_primary_nav(conn, user) do
    nav_items = nav_items_for_current_user(user)

    links =
      Enum.map(nav_items, fn {section, items} ->
        label = section

        path =
          items
          |> hd
          |> Keyword.get(:path)

        content_tag(:li) do
          link(label, to: path.(conn))
        end
      end)

    content_tag(:ul, links)
  end

  @doc """
  Renders person currently on call.
  """
  def render_on_call_person(conn) do
    people =
      case Artemis.Worker.PagerDutyOnCallSynchronizer.get_result() do
        nil ->
          []

        data ->
          data
          |> Enum.filter(&(Map.get(&1, "escalation_level") == 1))
          |> Enum.map(&Artemis.Helpers.deep_get(&1, ["user", "summary"]))
          |> Enum.uniq()
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_person.html", conn: conn, people: people)
  end

  @doc """
  Renders current status as a colored dot and link to more information.
  """
  def render_on_call_status(conn, user) do
    by_status = Artemis.GetIncidentReports.call(%{reports: [:count_by_status]}, user).count_by_status

    color =
      cond do
        has_status?(by_status, "triggered") -> "red"
        has_status?(by_status, "acknowledged") -> "yellow"
        has_status?(by_status, "resolved") -> "green"
        true -> "gray"
      end

    Phoenix.View.render(ArtemisWeb.LayoutView, "on_call_status.html", conn: conn, color: color)
  end

  defp has_status?(report, status) do
    case Map.get(report, status) do
      nil -> false
      0 -> false
      _ -> true
    end
  end

  @doc """
  Print date in human readable format
  """
  def render_date(value, format \\ "{Mfull} {D}, {YYYY}") do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
  end

  @doc """
  Print date in human readable format
  """
  def render_date_time(value, format \\ "{Mfull} {D}, {YYYY} at {h12}:{m}{am} {Zabbr}") do
    value
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.format!(format)
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
  def render_primary_nav_section(conn, nav_items, keys) do
    requested_keys = Enum.map(keys, &String.to_atom/1)
    allowed_keys = Keyword.keys(nav_items)
    section_keys = Enum.filter(requested_keys, &Enum.member?(allowed_keys, &1))

    Enum.map(section_keys, fn section ->
      entries = Keyword.get(nav_items, section)

      links =
        Enum.map(entries, fn item ->
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
  end

  @doc """
  Generates footer nav from nav items
  """
  def render_footer_nav(conn, user) do
    nav_items = nav_items_for_current_user(user)

    sections =
      Enum.map(nav_items, fn {section, items} ->
        links =
          Enum.map(items, fn item ->
            label = Keyword.get(item, :label)
            path = Keyword.get(item, :path)

            content_tag(:li) do
              link(label, to: path.(conn))
            end
          end)

        content_tag(:div, class: "section") do
          [
            content_tag(:h5, section),
            content_tag(:ul, links)
          ]
        end
      end)

    case sections == [] do
      true ->
        nil

      false ->
        per_column =
          (length(sections) / 3)
          |> Float.ceil()
          |> trunc()

        chunked = Enum.chunk_every(sections, per_column)

        Enum.map(chunked, fn sections ->
          content_tag(:div, sections, class: "column")
        end)
    end
  end

  @doc """
  Filter nav items by current users permissions
  """
  def nav_items_for_current_user(nil), do: []

  def nav_items_for_current_user(user) do
    Enum.reduce(nav_items(), [], fn {section, potential_items}, acc ->
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
  Generates pagination
  """
  def render_pagination(conn, data, options \\ [])

  def render_pagination(conn, %Scrivener.Page{} = data, options) do
    total_pages = Map.get(data, :total_pages, 1)
    args = Keyword.get(options, :args, [])
    params =
      options
      |> Keyword.get(:params, conn.query_params)
      |> Artemis.Helpers.keys_to_atoms()
      |> Map.delete(:page)
      |> Enum.into([])

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

    [link|links]
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

    [link|links]
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

  @doc """
  Generates empty table row if no records match
  """
  def render_table_row_if_empty(records, options \\ [])

  def render_table_row_if_empty(%{entries: entries}, options), do: render_table_row_if_empty(entries, options)

  def render_table_row_if_empty(records, options) when length(records) == 0 do
    message = Keyword.get(options, :message, "No records found")

    Phoenix.View.render(ArtemisWeb.LayoutView, "table_row_if_empty.html", message: message)
  end

  def render_table_row_if_empty(_records, _options), do: nil

  @doc """
  Generates search form
  """
  def render_search(conn, options \\ []) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "search.html", conn: conn, options: options)
  end

  @doc """
  Generates breadcrumbs from current URL
  """
  def render_breadcrumbs(conn) do
    path_sections =
      conn
      |> Map.get(:request_path)
      |> String.split("/", trim: true)

    breadcrumbs = get_root_breadcrumb() ++ get_breadcrumbs(path_sections)

    Phoenix.View.render(ArtemisWeb.LayoutView, "breadcrumbs.html", breadcrumbs: breadcrumbs)
  end

  defp get_root_breadcrumb, do: [["Home", "/"]]

  defp get_breadcrumbs(sections) when sections == [], do: []

  defp get_breadcrumbs(sections) do
    range = Range.new(0, length(sections) - 1)

    Enum.map(range, fn index ->
      title =
        sections
        |> Enum.at(index)
        |> String.replace("-", " ")
        |> Artemis.Helpers.titlecase()

      path =
        sections
        |> Enum.take(index + 1)
        |> Enum.join("/")

      [title, "/#{path}"]
    end)
  end

  @doc """
  Generates a notification
  """
  def render_notification(type, params \\ []) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "notification_#{type}.html", params)
  end

  @doc """
  Generates flash notifications
  """
  def render_flash_notifications(conn) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "flash_notifications.html", conn: conn)
  end

  @doc """
  Encodes JSON compatable data into a pretty printed string
  """
  def pretty_print_json_into_textarea(form, key) do
    form
    |> input_value(key)
    |> pretty_print_value()
  end

  defp pretty_print_value(value) when is_map(value), do: Jason.encode!(value, pretty: true)
  defp pretty_print_value(value), do: value
end
