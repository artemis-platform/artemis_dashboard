defmodule Artemis.Helpers.BulkAction do
  defmodule Result do
    defstruct data: [],
              errors: []
  end

  @moduledoc """
  Iterate over a list of records, calling the passed function for each. Return
  a standardized result set.

  Options include:

    halt_on_error: boolean (default false)
      When true, execution will stop after first failure.

  """

  @spec call(function(), List.t(), List.t()) :: any()
  def call(records, params \\ [], options) do
    action = Keyword.get(options, :do, Keyword.get(options, :action))
    halt_on_error? = Keyword.get(options, :halt_on_error, false)

    Enum.reduce_while(records, %Result{}, fn record, acc ->
      result =
        try do
          apply(action, [record | params])
        rescue
          error -> {:error, error}
        end

      error? = is_tuple(result) && elem(result, 0) == :error
      halt? = error? && halt_on_error?

      updated_data =
        case error? do
          true -> acc.data
          false -> [{record, result} | acc.data]
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
