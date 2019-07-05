defmodule ArtemisWeb.ViewHelper.Filter do
  use Phoenix.HTML

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
end
