defmodule Artemis.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias Artemis.Repo

  alias Artemis.Customers.Customer
  alias Artemis.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any customer changes.

  The broadcasted messages match the pattern:

    * {:created, %Customer{}}
    * {:updated, %Customer{}}
    * {:deleted, %Customer{}}

  """
  def subscribe_customers(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Artemis.PubSub, "user:#{key}:customers")
  end

  defp broadcast_customer(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Artemis.PubSub, "user:#{key}:customers", message)
  end

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers(scope)
      [%Customer{}, ...]

  """
  def list_customers(%Scope{} = scope) do
    Repo.all_by(Customer, user_id: scope.user.id)
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(scope, 123)
      %Customer{}

      iex> get_customer!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(%Scope{} = scope, id) do
    Repo.get_by!(Customer, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(scope, %{field: value})
      {:ok, %Customer{}}

      iex> create_customer(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(%Scope{} = scope, attrs) do
    with {:ok, customer = %Customer{}} <-
           %Customer{}
           |> Customer.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_customer(scope, {:created, customer})
      {:ok, customer}
    end
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(scope, customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(scope, customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Scope{} = scope, %Customer{} = customer, attrs) do
    true = customer.user_id == scope.user.id

    with {:ok, customer = %Customer{}} <-
           customer
           |> Customer.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_customer(scope, {:updated, customer})
      {:ok, customer}
    end
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(scope, customer)
      {:ok, %Customer{}}

      iex> delete_customer(scope, customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Scope{} = scope, %Customer{} = customer) do
    true = customer.user_id == scope.user.id

    with {:ok, customer = %Customer{}} <-
           Repo.delete(customer) do
      broadcast_customer(scope, {:deleted, customer})
      {:ok, customer}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(scope, customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Scope{} = scope, %Customer{} = customer, attrs \\ %{}) do
    true = customer.user_id == scope.user.id

    Customer.changeset(customer, attrs, scope)
  end
end
