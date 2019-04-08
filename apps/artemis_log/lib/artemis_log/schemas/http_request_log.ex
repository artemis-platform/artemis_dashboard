defmodule ArtemisLog.RequestLog do
  use ArtemisLog.Schema

  schema "http_request_logs" do
    field :endpoint, :string
    field :node, :string
    field :path, :string
    field :query_string, :string
    field :user_id, :integer
    field :user_name, :string

    timestamps()
  end

  # Callbacks

  def updatable_fields, do: [
    :endpoint,
    :node,
    :path,
    :query_string,
    :user_id,
    :user_name
  ]

  def required_fields, do: [
    :endpoint,
    :node,
    :path,
    :user_id,
    :user_name
  ]

  # Changesets

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, updatable_fields())
    |> validate_required(required_fields())
  end
end
