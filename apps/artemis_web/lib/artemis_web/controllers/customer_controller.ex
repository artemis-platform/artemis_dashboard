defmodule ArtemisWeb.CustomerController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.customer_path/3,
    permission: "customers:list",
    resource_type: "Customer"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.customer_event_log_path/4,
    permission: "customers:show",
    resource_getter: &Artemis.GetCustomer.call!/2,
    resource_id: "customer_id",
    resource_type: "Customer",
    resource_variable: :customer

  alias Artemis.CreateCustomer
  alias Artemis.Customer
  alias Artemis.DeleteCustomer
  alias Artemis.GetCustomer
  alias Artemis.ListCustomers
  alias Artemis.UpdateCustomer

  @preload []

  def index(conn, params) do
    authorize(conn, "customers:list", fn ->
      params = Map.put(params, :paginate, true)
      user = current_user(conn)
      customers = ListCustomers.call(params, user)

      assigns = [
        customers: customers
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "customers:create", fn ->
      customer = %Customer{}
      changeset = Customer.changeset(customer)

      render(conn, "new.html", changeset: changeset, customer: customer)
    end)
  end

  def create(conn, %{"customer" => params}) do
    authorize(conn, "customers:create", fn ->
      case CreateCustomer.call(params, current_user(conn)) do
        {:ok, customer} ->
          conn
          |> put_flash(:info, "Customer created successfully.")
          |> redirect(to: Routes.customer_path(conn, :show, customer))

        {:error, %Ecto.Changeset{} = changeset} ->
          customer = %Customer{}

          render(conn, "new.html", changeset: changeset, customer: customer)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "customers:show", fn ->
      customer = GetCustomer.call!(id, current_user(conn))

      render(conn, "show.html", customer: customer)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "customers:update", fn ->
      customer = GetCustomer.call(id, current_user(conn), preload: @preload)
      changeset = Customer.changeset(customer)

      render(conn, "edit.html", changeset: changeset, customer: customer)
    end)
  end

  def update(conn, %{"id" => id, "customer" => params}) do
    authorize(conn, "customers:update", fn ->
      case UpdateCustomer.call(id, params, current_user(conn)) do
        {:ok, customer} ->
          conn
          |> put_flash(:info, "Customer updated successfully.")
          |> redirect(to: Routes.customer_path(conn, :show, customer))

        {:error, %Ecto.Changeset{} = changeset} ->
          customer = GetCustomer.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, customer: customer)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "customers:delete", fn ->
      {:ok, _customer} = DeleteCustomer.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Customer deleted successfully.")
      |> redirect(to: Routes.customer_path(conn, :index))
    end)
  end
end
