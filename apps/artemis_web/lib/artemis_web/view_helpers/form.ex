defmodule ArtemisWeb.ViewHelper.Form do
  use Phoenix.HTML

  import Phoenix.HTML.Tag

  @doc """
  Returns a blank option value
  """
  def blank_option(), do: [key: " ", value: ""]

  @doc """
  Returns option data for a select field

  Options

    :key_field -> atom. required if passing a list of maps or list of keyword lists
    :value_field -> atom. required if passing a list of maps or list of keyword lists
    :blank_option -> boolean. include a blank option

  Example:

    select_options(["one", "two"])

  Returns:

    [
      [key: "one", value: "one"],
      [key: "two", value: "two"]
    ]

  """
  def select_options(data, options \\ []) do
    results =
      data
      |> Enum.map(&select_option(&1, options))
      |> Enum.reject(&is_nil(Keyword.get(&1, :value)))

    case Keyword.get(options, :blank_option) do
      true -> [blank_option() | results]
      _ -> results
    end
  end

  defp select_option(entry, options) when is_map(entry) do
    key_field = Keyword.get(options, :field) || Keyword.fetch!(options, :key_field)
    value_field = Keyword.get(options, :field) || Keyword.fetch!(options, :value_field)

    value = Map.get(entry, value_field)
    key = Map.get(entry, key_field) || value

    [
      key: key,
      value: value
    ]
  end

  defp select_option(entry, options) when is_list(entry) do
    key_field = Keyword.get(options, :key_field)
    value_field = Keyword.get(options, :value_field)

    value = Keyword.get(entry, value_field)
    key = Keyword.get(entry, key_field) || value

    [
      key: key,
      value: value
    ]
  end

  defp select_option(entry, _options), do: [key: entry, value: entry]

  @doc """
  Returns the value of a changeset field
  """
  def get_changeset_value(changeset, field), do: Ecto.Changeset.get_field(changeset, field)

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
