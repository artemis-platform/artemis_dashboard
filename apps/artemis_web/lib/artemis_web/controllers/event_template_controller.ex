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
  alias Artemis.EventQuestion
  alias Artemis.EventTemplate
  alias Artemis.DeleteEventTemplate
  alias Artemis.GetEventTemplate
  alias Artemis.ListEventTemplates
  alias Artemis.UpdateEventTemplate

  @preload [:event_questions, :team]

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
      event_template = %EventTemplate{event_questions: []}

      changeset =
        event_template
        |> EventTemplate.changeset()
        # |> add_event_question_template()

      render(conn, "new.html", changeset: changeset, event_template: event_template)
    end)
  end

  def create(conn, %{"event_template" => params}) do
    authorize(conn, "event-templates:create", fn ->
      params = Map.update!(params, "event_questions", &Map.values(&1))

      case CreateEventTemplate.call(params, current_user(conn)) do
        {:ok, event_template} ->
          conn
          |> put_flash(:info, "EventTemplate created successfully.")
          |> redirect(to: Routes.event_template_path(conn, :show, event_template))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_template = %EventTemplate{}
          changeset = add_association_changesets(changeset, params)

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

      changeset =
        event_template
        |> EventTemplate.changeset()
        # |> add_event_question_template()

      render(conn, "edit.html", changeset: changeset, event_template: event_template)
    end)
  end

  def update(conn, %{"id" => id, "event_template" => params}) do
    authorize(conn, "event-templates:update", fn ->
      params = Map.update!(params, "event_questions", &Map.values(&1))

      case UpdateEventTemplate.call(id, params, current_user(conn)) do
        {:ok, event_template} ->
          conn
          |> put_flash(:info, "EventTemplate updated successfully.")
          |> redirect(to: Routes.event_template_path(conn, :show, event_template))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_template = GetEventTemplate.call(id, current_user(conn), preload: @preload)
          changeset = add_association_changesets(changeset, params)

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

  # Helpers

  # TODO: deprecated, remove
  defp add_event_question_template(changeset, params \\ %{}) do
    Map.update!(changeset, :data, fn changeset_data ->
      event_questions =
        case Map.get(params, "event_questions") do
          nil -> Map.get(changeset_data, :event_questions)
          from_params -> Enum.map(from_params, &struct(EventQuestion, Artemis.Helpers.keys_to_atoms(&1)))
        end

      # TODO: hide template field in form using jQuery. Then add back with copy button
      # TODO: solve issue where validation errors in EventQuestion throw an exception instead of bubbling up a user friendly error
      # Map.put(changeset_data, :event_questions, [%EventQuestion{} | event_questions])
      Map.put(changeset_data, :event_questions, event_questions)
    end)
  end

  defp add_association_changesets(changeset, params) do
    Map.update!(changeset, :data, fn changeset_data ->
      event_questions =
        params
        |> Map.get("event_questions")
        |> Enum.map(fn association_params ->
          association_params = Artemis.Helpers.keys_to_atoms(association_params)

          EventQuestion.changeset(%EventQuestion{}, association_params)
        end)

      Map.put(changeset_data, :event_questions, event_questions)
    end)
  end
end
