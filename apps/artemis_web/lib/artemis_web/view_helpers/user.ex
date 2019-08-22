defmodule ArtemisWeb.ViewHelper.User do
  use Phoenix.HTML

  @doc """
  Render the current user initials from the `user.name` value:

    John Smith -> JS
    JOHN SMITH -> JS
    johN Smith -> JS
    John von Smith -> JVS
    John Smith-Doe -> JSD

  """
  def render_user_initials(%{name: name}) when is_bitstring(name) do
    name
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.first(&1))
    |> Enum.join()
    |> String.upcase()
  end

  def render_user_initials(_), do: nil
end
