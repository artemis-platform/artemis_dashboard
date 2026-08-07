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

  @optional [:notes]
  @required [:name]

  def optional, do: @optional
  def required, do: @required

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, optional())
    |> validate_required(required())
  end
end
