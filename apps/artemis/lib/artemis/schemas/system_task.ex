defmodule Artemis.SystemTask do
  use Artemis.Schema

  @primary_key false
  embedded_schema do
    field :extra_params, :map
    field :type, :string
  end

  # Callbacks

  def updatable_fields,
    do: [
      :extra_params,
      :type
    ]

  def required_fields,
    do: [
      :type
    ]

  def event_log_fields,
    do: [
      :extra_params,
      :type
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_extra_params()
  end

  # Validators

  defp validate_extra_params(%{changes: %{extra_params: data}} = changeset) do
    Jason.encode!(data)
    changeset
  rescue
    _ -> add_error(changeset, :extra_params, "invalid json")
  end

  defp validate_extra_params(changeset), do: changeset
end
