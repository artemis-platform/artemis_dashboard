defmodule Artemis.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false

  alias Artemis.Customer
  alias Artemis.Repo

  alias Artemis.Helpers.Filter
  alias Artemis.Helpers.Sort

  alias Phoenix.PubSub

  @topic "customers"

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> changeset(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def changeset(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list(params)
      [%Customer{}, ...]

  """
  def list(params) do
    Customer
    |> Filter.query(params, Artemis.Customers)
    |> Sort.query(params, Artemis.Customers)
    |> Repo.all()
  end

  @doc "Filter query"
  def filter(query, _key, _value), do: query

  @doc "Sort query"
  def sort(query, _key, _value), do: query

  @doc """
  Gets a single customer.

  Returns nil if the Customer does not exist.

  ## Examples

      iex> get(123)
      %Customer{}

      iex> get(456)
      nil

  """
  def get(id) do
    Repo.get_by(Customer, id: id)
  end

  @doc """
  Gets a single customer

  Raises exception if the Customer does not exist.

  ## Examples

      iex> get(123)
      %Customer{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id) do
    Repo.get_by!(Customer, id: id)
  end

  @doc """
  Fetches a single customer and returns an {:ok, resource} tuple

  Returns {:error, :not_found} if the Customer does not exist.

  ## Examples

      iex> fetch(123)
      {:ok, %Customer{}}

      iex> fetch(456)
      {:error, :not_found}

  """
  def fetch(id) do
    case get(id) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Customer{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    with {:ok, customer = %Customer{}} <-
           %Customer{}
           |> Customer.changeset(attrs)
           |> Repo.insert() do
      broadcast({:created, customer})
      {:ok, customer}
    end
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Customer{} = customer, attrs) do
    with {:ok, customer = %Customer{}} <-
           customer
           |> Customer.changeset(attrs)
           |> Repo.update() do
      broadcast({:updated, customer})
      {:ok, customer}
    end
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete(customer)
      {:ok, %Customer{}}

      iex> delete(customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Customer{} = customer) do
    with {:ok, customer = %Customer{}} <-
           Repo.delete(customer) do
      broadcast({:deleted, customer})
      {:ok, customer}
    end
  end

  @doc """
  Subscribes to notifications about any customer changes.
  """
  def subscribe(), do: PubSub.subscribe(Artemis.PubSub, "customers")
  def subscribe(%{id: id}), do: PubSub.subscribe(Artemis.PubSub, "#{@topic}:#{id}")
  def subscribe(%{"id" => id}), do: PubSub.subscribe(Artemis.PubSub, "#{@topic}:#{id}")
  def subscribe(id), do: PubSub.subscribe(Artemis.PubSub, "#{@topic}:#{id}")

  @doc """
  Broadcasted a payload. Common patterns include:

    * {:created, %Customer{}}
    * {:updated, %Customer{}}
    * {:deleted, %Customer{}}

  """
  def broadcast(payload), do: PubSub.broadcast(Artemis.PubSub, @topic, payload)
  def broadcast(%{id: id}, payload), do: PubSub.broadcast(Artemis.PubSub, "#{@topic}:#{id}", payload)
  def broadcast(%{"id" => id}, payload), do: PubSub.broadcast(Artemis.PubSub, "#{@topic}:#{id}", payload)
  def broadcast(id, payload), do: PubSub.broadcast(Artemis.PubSub, "#{@topic}:#{id}", payload)
end
