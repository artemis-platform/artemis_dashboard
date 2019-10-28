defmodule ArtemisWeb.CustomerController do
  use ArtemisWeb, :controller

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
      customers = ListCustomers.call(params, current_user(conn))

      render(conn, "index.html", customers: customers)
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

  def delete(conn, %{"id" => id}) do
    authorize(conn, "customers:delete", fn ->
      {:ok, _customer} = DeleteCustomer.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Customer deleted successfully.")
      |> redirect(to: Routes.customer_path(conn, :index))
    end)
  end

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "customers:list", fn ->
      user = current_user(conn)
      resource_type = "Customer"

      resource_id =
        Enum.find_value(params, fn {key, value} ->
          case String.match?(key, ~r/.*_id$/) do
            false -> nil
            true -> value
          end
        end)

      default_columns =
        case resource_id do
          nil -> ["action", "resource_id", "user_name", "inserted_at"]
          _ -> ["action", "user_name", "inserted_at"]
        end

      resource_type_filter = %{"filters" => %{"resource_type" => resource_type}}

      resource_id_filter =
        case resource_id do
          nil -> %{}
          value -> %{"filters" => %{"resource_id" => value}}
        end

      event_log_params =
        params
        |> Artemis.Helpers.deep_merge(resource_type_filter)
        |> Artemis.Helpers.deep_merge(resource_id_filter)
        # TODO: temporary for debugging, remove.
        |> Artemis.Helpers.deep_merge(%{"page_size" => "1"})

      event_logs = ArtemisLog.ListEventLogs.call(event_log_params, user)

      allowed_column_options = [
        to: fn conn, id ->
          case resource_id do
            nil -> ArtemisWeb.Router.Helpers.customer_path(conn, :index_event_log_details, id)
            _ -> ArtemisWeb.Router.Helpers.customer_customer_path(conn, :index_event_log_details, resource_id, id)
          end
        end
      ]

      allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)

      pagination_options = [
        action: :index_event_log_list,
        path: case resource_id do
          nil -> &ArtemisWeb.Router.Helpers.customer_path/3
          _ -> fn conn, page, options ->
            ArtemisWeb.Router.Helpers.customer_customer_path(conn, page, resource_id, options)
          end
        end
      ]

      assigns = [
        allowed_columns: allowed_columns,
        conn: conn,
        default_columns: default_columns,
        event_logs: event_logs,
        pagination_options: pagination_options,
        resource_type: resource_type
      ]

      render_format(conn, "index/event_log_list", assigns)
    end)
  end

  def index_event_log_details(conn, _params) do
    authorize(conn, "customers:show", fn ->
      render(conn, "index/event_log_details.html")
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "customers:list", fn ->
      user = current_user(conn)
      resource_type = "Customer"

      resource_id =
        Enum.find_value(params, fn {key, value} ->
          case String.match?(key, ~r/.*_id$/) do
            false -> nil
            true -> value
          end
        end)

      default_columns =
        case resource_id do
          nil -> ["action", "resource_id", "user_name", "inserted_at"]
          _ -> ["action", "user_name", "inserted_at"]
        end

      resource_type_filter = %{"filters" => %{"resource_type" => resource_type}}

      resource_id_filter =
        case resource_id do
          nil -> %{}
          value -> %{"filters" => %{"resource_id" => value}}
        end

      event_log_params =
        params
        |> Artemis.Helpers.deep_merge(resource_type_filter)
        |> Artemis.Helpers.deep_merge(resource_id_filter)
        # TODO: temporary for debugging, remove.
        |> Artemis.Helpers.deep_merge(%{"page_size" => "1"})

      event_logs = ArtemisLog.ListEventLogs.call(event_log_params, user)

      allowed_column_options = [
        to: fn conn, id ->
          case resource_id do
            nil -> ArtemisWeb.Router.Helpers.customer_path(conn, :show_event_log_details, id)
            _ -> ArtemisWeb.Router.Helpers.customer_customer_path(conn, :show_event_log_details, resource_id, id)
          end
        end
      ]

      allowed_columns = ArtemisWeb.EventLogView.data_table_allowed_columns(allowed_column_options)

      pagination_options = [
        action: :show_event_log_list,
        path: case resource_id do
          nil -> &ArtemisWeb.Router.Helpers.customer_path/3
          _ -> fn conn, page, options ->
            ArtemisWeb.Router.Helpers.customer_customer_path(conn, page, resource_id, options)
          end
        end
      ]

      assigns = [
        allowed_columns: allowed_columns,
        conn: conn,
        default_columns: default_columns,
        event_logs: event_logs,
        pagination_options: pagination_options,
        resource_type: resource_type
      ]

      render_format(conn, "show/event_log_list", assigns)
    end)
  end

  def show_event_log_details(conn, _params) do
    authorize(conn, "customers:show", fn ->
      render(conn, "show/event_log_details.html")
    end)
  end
end
