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

  def number_sign(value = %Decimal{}) do
    value
    |> Decimal.to_float()
    |> number_sign()
  end

  def number_sign(value) when is_bitstring(value) do
    value
    |> Integer.parse()
    |> elem(0)
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
  def number_sign_symbol(value, options \\ []) do
    case number_sign(value) do
      :positive -> "+"
      :negative -> "-"
      :zero -> Keyword.get(options, :zero, "")
    end
  end

  @doc """
  Returns a bitstring of the number and its sign symbol.

  Options:

      :pretty_print (default: false) Boolean - include comma delimiters in numbers
      :precision (default: 0) Integer - number of decimal places to include
      :symbol (default: nil) String - prefix result with a symbol, e.g. "$" would return `-$404`
      :zero_sign (default: nil) String - symbol to be shown for zero values, e.g. "+" would return `+0.00`

  """
  def number_and_sign_symbol(value, options \\ [])

  def number_and_sign_symbol(value = %Decimal{}, options) do
    value
    |> Decimal.to_float()
    |> number_and_sign_symbol(options)
  end

  def number_and_sign_symbol(value, options) do
    default_options = [
      pretty_print: false,
      precision: 0,
      symbol: nil,
      zero_sign: nil
    ]

    options = Keyword.merge(default_options, options)
    zero_sign = Keyword.get(options, :zero_sign)

    number_as_string =
      value
      |> abs()
      |> maybe_pretty_print(options)
      |> maybe_add_symbol(options)

    case number_sign(value) do
      :positive -> "+#{number_as_string}"
      :negative -> "-#{number_as_string}"
      :zero -> "#{zero_sign}#{number_as_string}"
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

  @doc """
  Returns a sign icon and value
  """
  def number_sign_icon_tag_and_value(value, options \\ []) do
    icon = number_sign_icon_tag(value, options)

    number =
      value
      |> abs()
      |> Integer.to_string()

    case icon do
      nil -> number
      _ -> content_tag(:span, [icon, number], class: "no-wrap")
    end
  end

  @doc """
  Pretty prints number with commas
  """
  def pretty_print_number(number, options \\ [])

  def pretty_print_number(number = %Decimal{}, options) do
    number
    |> Decimal.to_float()
    |> pretty_print_number(options)
  end

  def pretty_print_number(number, options) do
    default_options = [
      absolute_value: false,
      precision: 0
    ]

    merged_options = Keyword.merge(default_options, options)

    number
    |> maybe_absolute_value(merged_options)
    |> Number.Delimit.number_to_delimited(merged_options)
  end

  # Helpers

  defp maybe_absolute_value(number, options) do
    case Keyword.get(options, :absolute_value) do
      true -> abs(number)
      _ -> number
    end
  end

  defp maybe_add_symbol(value, options) do
    case Keyword.get(options, :symbol) do
      nil -> "#{value}"
      symbol -> "#{symbol}#{value}"
    end
  end

  defp maybe_pretty_print(number, options) do
    case Keyword.get(options, :pretty_print) do
      true -> pretty_print_number(number, options)
      _ -> number
    end
  end
end
