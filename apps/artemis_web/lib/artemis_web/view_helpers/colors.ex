defmodule ArtemisWeb.ViewHelper.Colors do
  @doc """
  Return the appropriate text color, white or black, depending on the
  background color.
  """
  def get_text_color(rgb_hex) do
    rgb_hex = String.upcase(rgb_hex)

    red = hex_to_integer(String.slice(rgb_hex, 0, 2))
    green = hex_to_integer(String.slice(rgb_hex, 2, 2))
    blue = hex_to_integer(String.slice(rgb_hex, 4, 2))

    total = red * 0.299 + green * 0.587 + blue * 0.114

    case total > 170 do
      true -> "#000"
      false -> "#fff"
    end
  end

  defp hex_to_integer(hex) do
    hex
    |> Base.decode16!()
    |> :binary.decode_unsigned()
  end
end
