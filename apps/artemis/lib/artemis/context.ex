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
      Iterates over a list of records and executes `call` on each.

      Options include:

        halt_on_error: boolean (default false)
          When true, execution will stop after first failure.

      """
      @spec call_many(List.t(), List.t(), List.t()) :: any()
      def call_many(records, params, options \\ []) do
        initial = %{
          data: [],
          errors: []
        }

        halt_on_error? = Keyword.get(options, :halt_on_error, false)

        Enum.reduce_while(records, initial, fn record, acc ->
          result =
            try do
              apply(__MODULE__, :call, [record | params])
            rescue
              error -> {:error, error}
            end

          error? = is_tuple(result) && elem(result, 0) == :error
          halt? = error? && halt_on_error?

          updated_data =
            case error? do
              true -> acc.data
              false -> [result | acc.data]
            end

          updated_errors =
            case error? do
              true -> [result | acc.errors]
              false -> acc.errors
            end

          acc =
            acc
            |> Map.put(:data, updated_data)
            |> Map.put(:errors, updated_errors)

          case halt? do
            true -> {:halt, acc}
            false -> {:cont, acc}
          end
        end)
      end
    end
  end
end
