defmodule ArtemisWeb.CustomerController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

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

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "customers:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.customer_path/3,
        resource_type: "Customer"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "customers:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "customers:show", fn ->
      customer_id = Map.get(params, "customer_id")
      customer = GetCustomer.call!(customer_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.customer_event_log_path/4,
        resource_id: customer_id,
        resource_type: "Customer"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:customer, customer)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "customers:show", fn ->
      customer_id = Map.get(params, "customer_id")
      customer = GetCustomer.call!(customer_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        customer: customer,
        event_log: event_log
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
