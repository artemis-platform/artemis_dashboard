defmodule ArtemisWeb.ViewHelper.Filter do
  use Phoenix.HTML

  @doc """
  Renders a filter button for setting query params in the URL
  """
  def filter_button(conn, label, values) do
    values =
      values
      |> Enum.into(%{})
      |> Artemis.Helpers.keys_to_strings()

    grouped =
      Enum.reduce(values, %{add: [], remove: []}, fn item, acc ->
        {_, value} = item

        add = Map.get(acc, :add, [])
        remove = Map.get(acc, :remove, [])

        case is_nil(value) do
          true -> Map.put(acc, :remove, [item | remove])
          false -> Map.put(acc, :add, [item | add])
        end
      end)

    values_to_add = Map.get(grouped, :add) |> Enum.into(%{})
    values_to_remove = Map.get(grouped, :remove) |> Enum.into(%{})

    new_query_params = %{"filters" => values_to_add}
    merged_query_params = Artemis.Helpers.deep_merge(conn.query_params, new_query_params)

    keys_to_remove = Map.keys(values_to_remove)
    merged_filters = Map.get(merged_query_params, "filters")
    updated_filters = Map.drop(merged_filters, keys_to_remove)
    updated_query_params = Map.put(merged_query_params, "filters", updated_filters)

    query_string = Plug.Conn.Query.encode(updated_query_params)
    path = "#{conn.request_path}?#{query_string}"

    active? =
      case conn.query_params["filters"] != nil do
        true ->
          present? = updated_query_params["filters"] != %{}
          updated_set = MapSet.new(updated_query_params["filters"])
          current_set = MapSet.new(conn.query_params["filters"])
          subset? = MapSet.subset?(updated_set, current_set)

          present? && subset?

        false ->
          false
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

  def filter_multi_select(conn, label, value, options) do
    filter_assigns = %{
      available: options,
      conn: conn,
      label: label,
      value: Artemis.Helpers.to_string(value)
    }

    Phoenix.View.render(ArtemisWeb.LayoutView, "filter_multi_select.html", filter_assigns)
  end
end
