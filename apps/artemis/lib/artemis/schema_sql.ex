defmodule Artemis.Schema.SQL do
  @moduledoc """
  Adds SQL specific schema functions
  """

  defmacro __using__(_options) do
    quote do
      alias Artemis.Repo
    end
  end
end
