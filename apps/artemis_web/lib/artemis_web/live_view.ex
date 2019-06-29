defmodule ArtemisWeb.LiveView do
  defmacro __using__(_options) do
    quote do
      use Phoenix.LiveView
      use Phoenix.HTML
    end
  end
end
