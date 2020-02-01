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

  def allowed_system_tasks,
    do: [
      %{
        action: fn params, user -> Artemis.DeleteAllIncidents.call(params, user) end,
        description: "Removes all incident records, so they can be regenerated from the original source.",
        name: "Delete All Incidents",
        type: "delete_all_incidents",
        verify: fn user -> Artemis.UserAccess.has_all?(user, ["system-tasks:create", "incidents:delete"]) end
      }
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> validate_extra_params()
    |> validate_type()
  end

  # Validators

  defp validate_extra_params(%{changes: %{extra_params: data}} = changeset) do
    Jason.encode!(data)
    changeset
  rescue
    _ -> add_error(changeset, :extra_params, "invalid json")
  end

  defp validate_extra_params(changeset), do: changeset

  defp validate_type(%{changes: %{type: type}} = changeset) do
    allowed_types = Enum.map(allowed_system_tasks(), & &1.type)

    case Enum.member?(allowed_types, type) do
      true -> changeset
      false -> add_error(changeset, :type, "invalid type")
    end
  end

  defp validate_type(changeset), do: changeset
end
