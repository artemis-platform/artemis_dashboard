defmodule Artemis.Context do
  defmodule Error do
    defexception message: "Context Error"
  end

  defmacro __using__(_options) do
    quote do
      import Artemis.Context
      import Artemis.Repo.Distinct
      import Artemis.Repo.Helpers
      import Artemis.Repo.Order
      import Artemis.Repo.SelectCount
      import Artemis.UserAccess

      require Logger

      alias Artemis.Event

      @doc """
      Wrapper around `Artemis.Helpers.BulkAction.call`. Iterates over a list of
      records and executes `__MODULE__.call()` on each.
      """
      @spec call_many(List.t(), List.t(), List.t()) :: any()
      def call_many(records, params, options \\ []) do
        action = fn record ->
          apply(__MODULE__, :call, [record | params])
        end

        options = Keyword.put(options, :action, action)

        Artemis.Helpers.BulkAction.call(records, options)
      end
    end
  end
end
