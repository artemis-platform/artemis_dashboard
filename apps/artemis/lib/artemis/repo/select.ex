defmodule Artemis.Repo.Select do
  require Ecto.Query

  @moduledoc """
  Functions that execute Ecto `select` queries
  """

  @doc """
  Helper function to parse options and potentially call `select_fields/3` and
  `exclude_fields/3`
  """
  def select_query(ecto_query, schema, params) do
    params = get_select_query_params(params)

    ecto_query
    |> maybe_exclude_fields(schema, params)
    |> maybe_select_fields(schema, params)
  end

  defp get_select_query_params(params) do
    params
    |> Enum.into(%{})
    |> Artemis.Helpers.keys_to_strings()
  end

  defp maybe_select_fields(ecto_query, schema, %{"select" => fields}) do
    select_fields(ecto_query, schema, fields)
  end

  defp maybe_select_fields(ecto_query, _, _), do: ecto_query

  defp maybe_exclude_fields(ecto_query, schema, %{"exclude" => fields}) do
    exclude_fields(ecto_query, schema, fields)
  end

  defp maybe_exclude_fields(ecto_query, _, _), do: ecto_query

  @doc """
  Add a select statement to an ecto query to include requested fields. Takes
  the schema as an argument and filters requested fields against existing ones.

  If a `select` statement already exists in the query, it attempts to detect it
  and use `select_merge` instead.

  Does not support associations.

  Example:

    select_fields(existing_ecto_query, Artemis.User, [:name, :invalid_field, :__meta__])

  Returns:

    #Ecto.Query<from u0 in Artemis.User, select: [:name]>

  """
  def select_fields(ecto_query, schema, fields) when is_list(fields) do
    selected_fields = get_selected_fields(schema, fields)

    case length(selected_fields) > 0 do
      true -> add_select_fields(ecto_query, selected_fields)
      false -> ecto_query
    end
  end

  def select_fields(ecto_query, _schema, _params), do: ecto_query

  @doc """
  Add a select statement to an ecto query to excluded requested fields. Takes
  the schema as an argument and filters requested fields against existing ones.

  A `nil` value will be returned for excluded fields.

  If a `select` statement already exists in the query, it attempts to detect it
  and use `select_merge` instead.

  Does not support associations.

  Example:

    exclude_fields(existing_ecto_query, Artemis.User, [:name, :invalid_field, :__meta__])

  Returns:

    #Ecto.Query<from u0 in Artemis.User, select: [<a list of all fields except for excluded ones>]>

  """
  def exclude_fields(ecto_query, schema, exclude_fields: fields) do
    exclude_fields(ecto_query, schema, fields)
  end

  def exclude_fields(ecto_query, schema, fields) when is_list(fields) do
    selected_fields = get_selected_fields_without_excluded(schema, fields)

    case length(selected_fields) > 0 do
      true -> add_select_fields(ecto_query, selected_fields)
      false -> ecto_query
    end
  end

  def exclude_fields(ecto_query, _schema, _params), do: ecto_query

  # Helpers

  defp get_selected_fields(schema, fields) do
    available_fields = get_available_fields(schema)
    requested_fields = Enum.map(fields, &Artemis.Helpers.to_string(&1))

    available_fields
    |> get_intersection(requested_fields)
    |> Enum.map(&String.to_existing_atom/1)
  end

  defp get_selected_fields_without_excluded(schema, fields) do
    available_fields = get_available_fields(schema)
    requested_fields = Enum.map(fields, &Artemis.Helpers.to_string(&1))

    available_fields
    |> get_difference(requested_fields)
    |> Enum.map(&String.to_existing_atom/1)
  end

  defp get_available_fields(schema) do
    schema.__schema__(:fields)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.reject(&String.starts_with?(&1, "__"))
  end

  defp get_intersection(available, requested) do
    MapSet.intersection(MapSet.new(available), MapSet.new(requested))
  end

  defp get_difference(available, requested) do
    MapSet.difference(MapSet.new(available), MapSet.new(requested))
  end

  defp add_select_fields(ecto_query, selected_fields) do
    case has_prior_select?(ecto_query) do
      false -> add_select_query(ecto_query, selected_fields)
      true -> add_select_merge_query(ecto_query, selected_fields)
    end
  end

  defp has_prior_select?(ecto_query) do
    ecto_query.select && true
  rescue
    _ -> false
  end

  defp add_select_query(ecto_query, selected_fields) do
    Ecto.Query.select(ecto_query, ^selected_fields)
  end

  defp add_select_merge_query(ecto_query, selected_fields) do
    fields_as_strings =
      selected_fields
      |> Enum.map(fn field -> "#{field}: i.#{field}" end)
      |> Enum.join(", ")

    field_map_as_string = "%{#{fields_as_strings}}"
    select_merge_as_string = "Ecto.Query.select_merge(ecto_query, [i], #{field_map_as_string})"

    # NOTE: Operation is safe since requested fields have been filtered against
    # existing ones before passed into `eval_string`.
    {result, _} = Code.eval_string(select_merge_as_string, [ecto_query: ecto_query], __ENV__)

    result
  end
end
