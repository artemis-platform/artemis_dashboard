defmodule ArtemisWeb.EventQuestionControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all event_questions", %{conn: conn} do
      conn = get(conn, Routes.event_question_path(conn, :index))
      assert html_response(conn, 200) =~ "Event Templates"
    end
  end

  describe "new event_question" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.event_question_path(conn, :new))
      assert html_response(conn, 200) =~ "New Event Template"
    end
  end

  describe "create event_question" do
    test "redirects to show when data is valid", %{conn: conn} do
      event_template = insert(:event_template)

      params = params_for(:event_question, event_template: event_template)

      conn = post(conn, Routes.event_question_path(conn, :create), event_question: params)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.event_question_path(conn, :show, id)

      conn = get(conn, Routes.event_question_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Title"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.event_question_path(conn, :create), event_question: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Event Template"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows event_question", %{conn: conn, record: record} do
      conn = get(conn, Routes.event_question_path(conn, :show, record))
      assert html_response(conn, 200) =~ "Title"
    end
  end

  describe "edit event_question" do
    setup [:create_record]

    test "renders form for editing chosen event_question", %{conn: conn, record: record} do
      conn = get(conn, Routes.event_question_path(conn, :edit, record))
      assert html_response(conn, 200) =~ "Edit Event Template"
    end
  end

  describe "update event_question" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.event_question_path(conn, :update, record), event_question: @update_attrs)
      assert redirected_to(conn) == Routes.event_question_path(conn, :show, record)

      conn = get(conn, Routes.event_question_path(conn, :show, record))
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.event_question_path(conn, :update, record), event_question: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Event Template"
    end
  end

  describe "delete event_question" do
    setup [:create_record]

    test "deletes chosen event_question", %{conn: conn, record: record} do
      conn = delete(conn, Routes.event_question_path(conn, :delete, record))
      assert redirected_to(conn) == Routes.event_question_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.event_question_path(conn, :show, record))
      end
    end
  end

  defp create_record(_) do
    record = insert(:event_question)

    {:ok, record: record}
  end
end
