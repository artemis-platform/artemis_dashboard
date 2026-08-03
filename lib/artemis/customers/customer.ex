defmodule Artemis.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :name, :string
    field :notes, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs, user_scope) do
    customer
    |> cast(attrs, [:name, :notes])
    |> validate_required([:name, :notes])
    |> put_change(:user_id, user_scope.user.id)
  end
end
