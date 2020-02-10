defmodule ArtemisWeb.CustomerController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.CustomerView.available_bulk_actions(),
    path: &Routes.customer_path(&1, :index),
    permission: "customers:list"

  use ArtemisWeb.Controller.CommentsShow,
    path: &Routes.customer_path/3,
    permission: "customers:show",
    resource_getter: &Artemis.GetCustomer.call!/2,
    resource_id_key: "customer_id",
    resource_type: "Customer"

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
  alias Artemis.ListClouds
  alias Artemis.ListCustomers
  alias Artemis.UpdateCustomer

  @preload [:clouds, :data_centers, :machines]

  def index(conn, params) do
    authorize(conn, "customers:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, @preload)

      customers = ListCustomers.call(params, user)
      allowed_bulk_actions = ArtemisWeb.CustomerView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
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
      user = current_user(conn)
      customer = GetCustomer.call!(id, user, preload: @preload)
      associated_clouds = list_related_clouds(conn, customer, user)

      assigns = [
        customer: customer,
        associated_clouds: associated_clouds
      ]

      render(conn, "show.html", assigns)
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

  # Helpers

  defp list_related_clouds(conn, customer, user) do
    params = %{
      "filters" => %{
        "customer_id" => customer.id
      },
      "paginate" => false,
      "preload" => [
        :data_centers,
        :machines
      ]
    }

    conn
    |> Map.get(:query_params)
    |> Artemis.Helpers.deep_merge(params)
    |> ListClouds.call(user)
  end
end
