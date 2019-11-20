defmodule Artemis.Context do
  defmodule Error do
    defexception message: "Context Error"
  end

  defmacro __using__(_options) do
    quote do
      import Artemis.Context
      import Artemis.Repo.Helpers
      import Artemis.Repo.Order
      import Artemis.UserAccess

      require Logger

      alias Artemis.Event

      @doc """
      Iterates over a list of records and executes `__MODULE__.call()` on each.

      Options include:

        halt_on_error: boolean (default false)
          When true, execution will stop after first failure.

      """
      @spec call_many(List.t(), List.t(), List.t()) :: any()
      def call_many(records, params, options \\ []) do
        Artemis.Helpers.BulkAction.call(records) do
          fn record ->
            apply(__MODULE__, :call, [record | params])
          end
        end
      end
    end
  end
end
