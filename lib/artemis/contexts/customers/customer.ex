defmodule Artemis.Customer do
  @moduledoc """
  The Customer schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :name, :string
    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :notes])
    |> validate_required([:name, :notes])
  end
end
