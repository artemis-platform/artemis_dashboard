defmodule ArtemisWeb.ViewHelper.Filter do
  use Phoenix.HTML

  @doc """
  Renders top level a page filters
  """
  def page_filters(options) do
    content_tag(:div, class: "page-filters") do
      [
        content_tag(:h5) do
          [
            content_tag(:i, "", class: "ui icon filter"),
            "Data Filters"
          ]
        end
      ] ++ Keyword.get(options, :do, [])
    end
  end

  @doc """
  Renders a filter toggle for setting query params in the URL
  """
  def filter_toggle(conn, label, key, value) do
    key = if is_atom(key), do: Atom.to_string(key), else: key

    current_query_params = conn.query_params
    current_filter_params = Map.get(current_query_params, "filters", %{})

    active? = Map.get(current_filter_params, key) == value
    id = "filter-toggle-#{Artemis.Helpers.UUID.call()}"

    values =
      case active? do
        true -> Map.put(%{}, key, nil)
        false -> Map.put(%{}, key, value)
      end

    updated_filter_params = ArtemisWeb.ViewHelper.QueryParams.update_query_params(current_filter_params, values)
    updated_query_params = Map.put(conn.query_params, "filters", updated_filter_params)
    updated_query_string = Plug.Conn.Query.encode(updated_query_params)
    path = "#{conn.request_path}?#{updated_query_string}"

    input_options = [
      checked: active?,
      id: id,
      onclick: "location.href='#{path}'",
      type: "checkbox"
    ]

    content_tag(:div, class: "ui toggle checkbox") do
      [
        tag(:input, input_options),
        content_tag(:label, label, for: id)
      ]
    end
  end

  @doc """
  Renders a filter button for setting query params in the URL under the `filters` key
  """
  def filter_button(conn, label, values) do
    filter_data = get_filter_data(conn, values)

    class =
      case filter_data.active? do
        true -> "ui basic button blue"
        false -> "ui basic button"
      end

    options = [
      class: class,
      onclick: "location.href='#{filter_data.path}'",
      type: "button"
    ]

    content_tag(:button, label, options)
  end

  @doc """
  Renders a filter link for setting query params in the URL under the `filters` key
  """
  def filter_link(conn, label, values) do
    filter_data = get_filter_data(conn, values)

    class = if filter_data.active?, do: "active"

    options = [
      class: class,
      href: filter_data.path
    ]

    content_tag(:a, label, options)
  end

  defp get_filter_data(conn, values) do
    current_query_params = conn.query_params
    current_filter_params = Map.get(current_query_params, "filters", %{})
    updated_filter_params = ArtemisWeb.ViewHelper.QueryParams.update_query_params(current_filter_params, values)
    updated_query_params = Map.put(conn.query_params, "filters", updated_filter_params)
    updated_query_string = Plug.Conn.Query.encode(updated_query_params)
    path = "#{conn.request_path}?#{updated_query_string}"

    active? =
      case current_filter_params != nil do
        true ->
          updated_size = Artemis.Helpers.deep_size(updated_query_params)
          updated_set = MapSet.new(updated_query_params)

          current_size = Artemis.Helpers.deep_size(current_query_params)
          current_set = MapSet.new(current_query_params)

          add? = current_size <= updated_size
          present? = updated_filter_params != %{}
          subset? = MapSet.subset?(updated_set, current_set)

          add? && present? && subset?

        false ->
          false
      end

    %{
      active?: active?,
      path: path
    }
  end

  @doc """
  Render a input filter form element
  """
  def filter_input_field(conn, label, value) do
    filter_assigns = %{
      conn: conn,
      label: label,
      value: Artemis.Helpers.to_string(value)
    }

    Phoenix.View.render(ArtemisWeb.LayoutView, "filter_input_field.html", filter_assigns)
  end

  @doc """
  Render a multi select filter form field inside a self-contained form tag
  """
  def filter_multi_select(conn, label, value, options) do
    filter_assigns = %{
      available: options,
      conn: conn,
      label: label,
      value: Artemis.Helpers.to_string(value)
    }

    Phoenix.View.render(ArtemisWeb.LayoutView, "filter_multi_select.html", filter_assigns)
  end

  @doc """
  Render a multi select filter form field
  """
  def filter_multi_select_field(conn, form, label, value, options) do
    value = Artemis.Helpers.to_string(value)
    selected = Artemis.Helpers.deep_get(conn, [:query_params, "filters", value]) || []
    class = if length(selected) > 0, do: "active"

    filter_assigns = %{
      available: options,
      class: class,
      form: form,
      label: label,
      selected: selected,
      value: value
    }

    Phoenix.View.render(ArtemisWeb.LayoutView, "filter_multi_select_field.html", filter_assigns)
  end
end
