defmodule ArtemisWeb.ViewHelper.Values do
  use Phoenix.HTML

  import Phoenix.HTML.Tag

  @doc """
  Render a list of key value pairs
  """
  def render_key_value_list(items) do
    rows = Enum.map(items, fn [key, value] ->
      content_tag(:li) do
        [
          content_tag(:div, class: "key") do
            key
          end,
          content_tag(:div, class: "value") do
            value
          end
        ]
      end
    end)

    content_tag(:ul, rows, class: "key-value-list")
  end
end
