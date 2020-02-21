defmodule ArtemisWeb.EventTemplateController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.EventTemplateView.available_bulk_actions(),
    path: &Routes.event_template_path(&1, :index),
    permission: "event-templates:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.event_template_path/3,
    permission: "event-templates:list",
    resource_type: "EventTemplate"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.event_template_event_log_path/4,
    permission: "event-templates:show",
    resource_getter: &Artemis.GetEventTemplate.call!/2,
    resource_id: "event_template_id",
    resource_type: "EventTemplate",
    resource_variable: :event_template

  alias Artemis.CreateEventTemplate
  alias Artemis.EventTemplate
  alias Artemis.DeleteEventTemplate
  alias Artemis.GetEventTemplate
  alias Artemis.ListEventTemplates
  alias Artemis.UpdateEventTemplate

  @preload [:team]

  def index(conn, params) do
    authorize(conn, "event-templates:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, @preload)

      event_templates = ListEventTemplates.call(params, user)
      allowed_bulk_actions = ArtemisWeb.EventTemplateView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        event_templates: event_templates
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "event-templates:create", fn ->
      event_template = %EventTemplate{}
      changeset = EventTemplate.changeset(event_template)

      render(conn, "new.html", changeset: changeset, event_template: event_template)
    end)
  end

  def create(conn, %{"event_template" => params}) do
    authorize(conn, "event-templates:create", fn ->
      case CreateEventTemplate.call(params, current_user(conn)) do
        {:ok, event_template} ->
          conn
          |> put_flash(:info, "EventTemplate created successfully.")
          |> redirect(to: Routes.event_template_path(conn, :show, event_template))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_template = %EventTemplate{}

          render(conn, "new.html", changeset: changeset, event_template: event_template)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "event-templates:show", fn ->
      event_template = GetEventTemplate.call!(id, current_user(conn), preload: @preload)

      render(conn, "show.html", event_template: event_template)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "event-templates:update", fn ->
      event_template = GetEventTemplate.call(id, current_user(conn), preload: @preload)
      changeset = EventTemplate.changeset(event_template)

      render(conn, "edit.html", changeset: changeset, event_template: event_template)
    end)
  end

  def update(conn, %{"id" => id, "event_template" => params}) do
    authorize(conn, "event-templates:update", fn ->
      case UpdateEventTemplate.call(id, params, current_user(conn)) do
        {:ok, event_template} ->
          conn
          |> put_flash(:info, "EventTemplate updated successfully.")
          |> redirect(to: Routes.event_template_path(conn, :show, event_template))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_template = GetEventTemplate.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, event_template: event_template)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "event-templates:delete", fn ->
      {:ok, _event_template} = DeleteEventTemplate.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "EventTemplate deleted successfully.")
      |> redirect(to: Routes.event_template_path(conn, :index))
    end)
  end
end
