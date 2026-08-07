defmodule Artemis.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias Artemis.Repo

  alias Artemis.Customer
  alias Artemis.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any customer changes.

  The broadcasted messages match the pattern:

    * {:created, %Customer{}}
    * {:updated, %Customer{}}
    * {:deleted, %Customer{}}

  """
  def subscribe(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Artemis.PubSub, "user:#{key}:customers")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Artemis.PubSub, "user:#{key}:customers", message)
  end

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list(scope)
      [%Customer{}, ...]

  """
  def list(%Scope{} = scope) do
    Repo.all_by(Customer, user_id: scope.user.id)
  end

  @doc """
  Gets a single customer.

  Returns nil if the Customer does not exist.

  ## Examples

      iex> get(scope, 123)
      %Customer{}

      iex> get(scope, 456)
      nil

  """
  def get(%Scope{} = scope, id) do
    Repo.get_by(Customer, id: id, user_id: scope.user.id)
  end

  @doc """
  Fetches a single customer and returns an {:ok, resource} tuple

  Returns {:error, :not_found} if the Customer does not exist.

  ## Examples

      iex> fetch(scope, 123)
      {:ok, %Customer{}}

      iex> fetch(scope, 456)
      {:error, :not_found}

  """
  def fetch(%Scope{} = scope, id) do
    case get(scope, id) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create(scope, %{field: value})
      {:ok, %Customer{}}

      iex> create(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(%Scope{} = scope, attrs) do
    with {:ok, customer = %Customer{}} <-
           %Customer{}
           |> Customer.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, customer})
      {:ok, customer}
    end
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update(scope, customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update(scope, customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Scope{} = scope, %Customer{} = customer, attrs) do
    true = customer.user_id == scope.user.id

    with {:ok, customer = %Customer{}} <-
           customer
           |> Customer.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, customer})
      {:ok, customer}
    end
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete(scope, customer)
      {:ok, %Customer{}}

      iex> delete(scope, customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Scope{} = scope, %Customer{} = customer) do
    true = customer.user_id == scope.user.id

    with {:ok, customer = %Customer{}} <-
           Repo.delete(customer) do
      broadcast(scope, {:deleted, customer})
      {:ok, customer}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> changeset(scope, customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def changeset(%Scope{} = scope, %Customer{} = customer, attrs \\ %{}) do
    true = customer.user_id == scope.user.id

    Customer.changeset(customer, attrs, scope)
  end
end
