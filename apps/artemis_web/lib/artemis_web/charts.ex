defmodule ArtemisWeb.Charts do
  @moduledoc """

  """

  @callback fetch_data(Keyword.t(), Map.t()) :: Map.t()
  @callback render(Map.t(), Keyword.t()) :: any()

  defmacro __using__(_options) do
    quote do
      import ArtemisWeb.Charts
      import ArtemisWeb.Guardian.Helpers
      import ArtemisWeb.ViewHelper.Charts

      @behaviour ArtemisWeb.Charts

      # Allow defined `@callback`s to be overwritten

      defoverridable ArtemisWeb.Charts
    end
  end
end
