defmodule ArtemisWeb.SharedJobView do
  use ArtemisWeb, :view

  def status_color(%{status: status}) when is_bitstring(status) do
    case String.downcase(status) do
      "completed" -> "green"
      true -> nil
    end
  end

  def status_color(_), do: nil
end
