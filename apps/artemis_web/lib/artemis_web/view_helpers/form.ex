defmodule ArtemisWeb.ViewHelper.Form do
  use Phoenix.HTML

  import Phoenix.HTML.Tag

  @doc """
  Returns a blank option value
  """
  def blank_option(), do: [key: " ", value: ""]

  @doc """
  Render a standalone select input form field. Note, if using `form_for`, use
  the Phoenix built-in function `select` instead.

  Expects `data` to be in the form of a list of keyword pairs:

      [
        [key: "Option One", value: "option-value-1"],
        [key: "Option Two", value: "option-value-2"]
      ]

  """
  def select_tag(data, options \\ []) do
    name = Keyword.get(options, :name)
    placeholder = Keyword.get(options, :placeholder)
    class = Keyword.get(options, :class, "enhanced")

    content_tag(:select, class: class, name: name, placeholder: placeholder) do
      Enum.map(data, fn [key: key, value: value] ->
        content_tag(:option, value: value) do
          key
        end
      end)
    end
  end
end
