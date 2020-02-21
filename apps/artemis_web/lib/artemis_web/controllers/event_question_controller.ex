defmodule ArtemisWeb.EventQuestionController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.EventQuestionView.available_bulk_actions(),
    path: &Routes.event_question_path(&1, :index),
    permission: "event-questions:list"

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.event_question_path/3,
    permission: "event-questions:list",
    resource_type: "EventQuestion"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.event_question_event_log_path/4,
    permission: "event-questions:show",
    resource_getter: &Artemis.GetEventQuestion.call!/2,
    resource_id: "event_question_id",
    resource_type: "EventQuestion",
    resource_variable: :event_question

  alias Artemis.CreateEventQuestion
  alias Artemis.EventQuestion
  alias Artemis.DeleteEventQuestion
  alias Artemis.GetEventQuestion
  alias Artemis.ListEventQuestions
  alias Artemis.UpdateEventQuestion

  @preload [:event_template]

  def index(conn, params) do
    authorize(conn, "event-questions:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, @preload)

      event_questions = ListEventQuestions.call(params, user)
      allowed_bulk_actions = ArtemisWeb.EventQuestionView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        event_questions: event_questions
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "event-questions:create", fn ->
      event_question = %EventQuestion{}
      changeset = EventQuestion.changeset(event_question)

      render(conn, "new.html", changeset: changeset, event_question: event_question)
    end)
  end

  def create(conn, %{"event_question" => params}) do
    authorize(conn, "event-questions:create", fn ->
      case CreateEventQuestion.call(params, current_user(conn)) do
        {:ok, event_question} ->
          conn
          |> put_flash(:info, "EventQuestion created successfully.")
          |> redirect(to: Routes.event_question_path(conn, :show, event_question))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_question = %EventQuestion{}

          render(conn, "new.html", changeset: changeset, event_question: event_question)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "event-questions:show", fn ->
      event_question = GetEventQuestion.call!(id, current_user(conn), preload: @preload)

      render(conn, "show.html", event_question: event_question)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "event-questions:update", fn ->
      event_question = GetEventQuestion.call(id, current_user(conn), preload: @preload)
      changeset = EventQuestion.changeset(event_question)

      render(conn, "edit.html", changeset: changeset, event_question: event_question)
    end)
  end

  def update(conn, %{"id" => id, "event_question" => params}) do
    authorize(conn, "event-questions:update", fn ->
      case UpdateEventQuestion.call(id, params, current_user(conn)) do
        {:ok, event_question} ->
          conn
          |> put_flash(:info, "EventQuestion updated successfully.")
          |> redirect(to: Routes.event_question_path(conn, :show, event_question))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_question = GetEventQuestion.call(id, current_user(conn), preload: @preload)

          render(conn, "edit.html", changeset: changeset, event_question: event_question)
      end
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "event-questions:delete", fn ->
      {:ok, _event_question} = DeleteEventQuestion.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "EventQuestion deleted successfully.")
      |> redirect(to: Routes.event_question_path(conn, :index))
    end)
  end
end
