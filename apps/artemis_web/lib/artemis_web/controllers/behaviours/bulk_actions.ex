defmodule ArtemisWeb.Controller.Behaviour.BulkActions do
  @moduledoc """
  Functions to process Bulk Actions related to the resource type
  """

  @callback index_bulk_actions(map(), map()) :: any()

  defmacro __using__(_options) do
    quote do
      import ArtemisWeb.Controller.Behaviour.BulkActions

      @behaviour ArtemisWeb.Controller.Behaviour.BulkActions

      # Allow defined `@callback`s to be overwritten

      defoverridable ArtemisWeb.Controller.Behaviour.BulkActions
    end
  end
end
