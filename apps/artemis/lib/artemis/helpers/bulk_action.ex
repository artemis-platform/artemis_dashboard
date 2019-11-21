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

  ## Example Usage

  The function can be passed as a `do` block:

    BulkAction.call([1,2,3]) do
      fn (item) -> item + 1 end
    end

    => %BulkAction.Result{
      data: [{3, 4}, {2, 3}, {1, 2}],
      errors: []
    }

  Or under the `action` key:

    BulkAction.call([1,2,3], action: fn (item) -> item + 1 end)

    => %BulkAction.Result{
      data: [{3, 4}, {2, 3}, {1, 2}],
      errors: []
    }

  Additional parameters can be passed as a list as an optional second argument:

    BulkAction.call([1,2,3], [8, 20]) do
      fn (item, add_by, multiply_by) -> (item + add_by) * multiply_by
    end

    => %BulkAction.Result{
      data: [{3, 220}, {2, 200}, {1, 180}],
      errors: []
    }

  The second argument changes the arity of the action function.

  ## Return Value

  Returns a struct:

      %Artemis.Helpers.BulkAction{
        data: [],
        errors: []
      }

  Where `data` is a keyword list of successful results and `errors` is a list
  of errors.

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
          true -> [{record, result} | acc.errors]
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
