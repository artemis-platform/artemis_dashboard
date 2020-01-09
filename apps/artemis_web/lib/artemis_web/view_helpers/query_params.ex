defmodule ArtemisWeb.ViewHelper.QueryParams do
  @doc """
  Adds or drops values from existing query params.

  Drops any key/value pairs where the final value is either:

      nil
      ""   # Empty Bitstring
      []   # Empty List
      %{}  # Empty Map

  """
  def update_query_params(current_query_params, values) do
    values =
      values
      |> Enum.into(%{})
      |> Artemis.Helpers.keys_to_strings()

    current_query_params
    |> Artemis.Helpers.deep_merge(values)
    |> Artemis.Helpers.deep_drop_by_value(nil)
    |> Artemis.Helpers.deep_drop_by_value("")
    |> Artemis.Helpers.deep_drop_by_value([])
    |> Artemis.Helpers.deep_drop_by_value(%{})
  end
end
