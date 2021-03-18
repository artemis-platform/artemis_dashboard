defmodule ArtemisWeb.KeyValueController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.KeyValueView.available_bulk_actions(),
    path: &Routes.key_value_path(&1, :index),
    permission: "key-values:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.key_value_path/3,
    permission: "key-values:list",
    resource_type: "KeyValue"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.key_value_event_log_path/4,
    permission: "key-values:show",
    resource_getter: &Artemis.GetKeyValue.call!/2,
    resource_id: "key_value_id",
    resource_type: "KeyValue",
    resource_variable: :key_value

  alias Artemis.CreateKeyValue
  alias Artemis.KeyValue
  alias Artemis.DeleteKeyValue
  alias Artemis.GetKeyValue
  alias Artemis.ListKeyValues
  alias Artemis.UpdateKeyValue

  @preload []

  def index(conn, params) do
    authorize(conn, "key-values:list", fn ->
      user = current_user(conn)
      params = get_index_params(params)
      key_values = ListKeyValues.call(params, user)
      allowed_bulk_actions = ArtemisWeb.KeyValueView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        key_values: key_values
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "key-values:create", fn ->
      key_value = %KeyValue{}
      changeset = KeyValue.changeset(key_value)

      render(conn, "new.html", changeset: changeset, key_value: key_value)
    end)
  end

  def create(conn, %{"key_value" => params}) do
    authorize(conn, "key-values:create", fn ->
      params = process_params(params)

      case CreateKeyValue.call(params, current_user(conn)) do
        {:ok, key_value} ->
          conn
          |> put_flash(:info, "Key Value created successfully.")
          |> redirect(to: Routes.key_value_path(conn, :show, key_value))

        {:error, %Ecto.Changeset{} = changeset} ->
          key_value = %KeyValue{}

          render(conn, "new.html", changeset: changeset, key_value: key_value)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "key-values:show", fn ->
      key_value = GetKeyValue.call!(id, current_user(conn))

      render(conn, "show.html", key_value: key_value)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "key-values:update", fn ->
      key_value = GetKeyValue.call(id, current_user(conn), preload: @preload)
      changeset = KeyValue.changeset(key_value)

      render(conn, "edit.html", changeset: changeset, key_value: key_value)
    end)
  end

  def update(conn, %{"id" => id, "key_value" => params}) do
    authorize(conn, "key-values:update", fn ->
      params = process_params(params)

      case UpdateKeyValue.call(id, params, current_user(conn)) do
        {:ok, key_value} ->
          conn
          |> put_flash(:info, "Key Value updated successfully.")
          |> redirect(to: Routes.key_value_path(conn, :show, key_value))

        {:error, %Ecto.Changeset{} = changeset} ->
          key_value = GetKeyValue.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, key_value: key_value)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "key-values:delete", fn ->
      {:ok, _key_value} = DeleteKeyValue.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Key Value deleted successfully.")
      |> redirect(to: Routes.key_value_path(conn, :index))
    end)
  end

  # Helpers

  defp get_index_params(params) do
    params
    |> Map.put(:exclude, [:value])
    |> Map.put(:paginate, true)
  end

  defp process_params(params) do
    params = Artemis.Helpers.keys_to_strings(params)

    params
    |> process_param("key")
    |> process_param("value")
  end

  defp process_param(params, key) do
    updated =
      params
      |> Map.get(key)
      |> Kernel.||("")
      |> String.trim("\"")
      |> Artemis.KeyValue.decode()

    Map.put(params, key, updated)
  end
end
