defmodule Artemis.KeyValue do
  use Artemis.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "key_values" do
    field :expire_at, :utc_datetime
    field :key, :binary
    field :size, :integer
    field :value, :binary

    timestamps()
  end

  # Callbacks

  def updatable_fields,
    do: [
      :expire_at,
      :key,
      :size,
      :value
    ]

  def required_fields,
    do: [
      :key,
      :value,
      :size
    ]

  def event_log_fields,
    do: [
      :id
    ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    params = get_changeset_params(params)

    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
    |> unique_constraint(:key)
  end

  defp get_changeset_params(params) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> maybe_add_byte_size()
  end

  defp maybe_add_byte_size(params) do
    value = Map.get(params, "value")

    case is_binary(value) do
      true -> Map.put(params, "size", byte_size(value))
      false -> params
    end
  end

  # Helpers

  def decode(value) when is_binary(value) do
    :erlang.binary_to_term(value)
  rescue
    _ in ArgumentError -> value
  end

  def decode(value), do: value

  def encode(value) when is_binary(value), do: value
  def encode(value), do: :erlang.term_to_binary(value)
end
