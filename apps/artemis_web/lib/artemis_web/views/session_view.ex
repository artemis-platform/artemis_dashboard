defmodule ArtemisWeb.SessionView do
  use ArtemisWeb, :view

  def get_provider_color(%{title: title}) do
    case title do
      "Log in as System User" -> "red"
      "Google" -> "blue"
      _ -> "gray"
    end
  end
end
