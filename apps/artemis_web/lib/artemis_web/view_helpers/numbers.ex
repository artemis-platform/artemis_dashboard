defmodule ArtemisWeb.ViewHelper.Numbers do
  import Phoenix.HTML.Tag

  @doc """
  Returns the sign of a given number. Returns:

      :positive
      :zero
      :negative

  """
  def number_sign(value) when is_number(value) do
    cond do
      value > 0 -> :positive
      value < 0 -> :negative
      true -> :zero
    end
  end

  def number_sign(value) when is_bitstring(value) do
    value
    |> String.to_integer()
    |> number_sign()
  end

  def number_sign(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> number_sign()
  end

  @doc """
  Returns a bitstring symbol for a given number's sign.
  """
  def number_sign_symbol(value) do
    case number_sign(value) do
      :positive -> "+"
      :negative -> "-"
      :zero -> ""
    end
  end

  @doc """
  Returns a bitstring of the number and its sign symbol.
  """
  def number_and_sign_symbol(value) do
    case number_sign(value) do
      :positive -> "+#{value}"
      :negative -> value
      :zero -> value
    end
  end

  @doc """
  Returns a Semantic UI compatible caret icon class for a given number's sign.
  """
  def number_sign_icon_class(value, options \\ []) do
    icon = Keyword.get(options, :icon, "caret")

    case number_sign(value) do
      :positive -> "#{icon} up"
      :negative -> "#{icon} down"
      :zero -> ""
    end
  end

  @doc """
  Returns a Semantic UI compatible caret icon tag for a given number's sign.
  """
  def number_sign_icon_tag(value, options \\ []) do
    sign = number_sign(value)
    class = "ui icon " <> number_sign_icon_class(value)

    color =
      cond do
        Keyword.get(options, :color) == false -> ""
        sign == :positive -> "green"
        sign == :negative -> "red"
        true -> ""
      end

    html_options =
      options
      |> Keyword.put(:class, class)
      |> Keyword.update!(:class, &"#{&1} #{color}")

    case sign do
      :zero -> nil
      _signed -> content_tag(:i, "", html_options)
    end
  end
end
