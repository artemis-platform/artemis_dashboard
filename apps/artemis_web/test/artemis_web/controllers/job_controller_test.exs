defmodule ArtemisWeb.JobControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "New Name", status: "Queued"}
  @update_attrs %{name: "Updated Name", status: "Completed"}
  @invalid_attrs %{raw_data: "{"}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all jobs", %{conn: conn} do
      conn = get(conn, Routes.job_path(conn, :index))
      assert html_response(conn, 200) =~ "Jobs"
    end
  end

  describe "new job" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.job_path(conn, :new))
      assert html_response(conn, 200) =~ "New Job"
    end
  end

  describe "create job" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.job_path(conn, :create), job: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.job_path(conn, :show, id)

      conn = get(conn, Routes.job_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.job_path(conn, :create), job: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Job"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows job", %{conn: conn, record: record} do
      conn = get(conn, Routes.job_path(conn, :show, record._id))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit job" do
    setup [:create_record]

    test "renders form for editing chosen job", %{conn: conn, record: record} do
      conn = get(conn, Routes.job_path(conn, :edit, record._id))
      assert html_response(conn, 200) =~ "Edit Job"
    end
  end

  describe "update job" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.job_path(conn, :update, record._id), job: @update_attrs)
      assert redirected_to(conn) == Routes.job_path(conn, :show, record._id)

      conn = get(conn, Routes.job_path(conn, :show, record._id))
      assert html_response(conn, 200) =~ "Updated Name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.job_path(conn, :update, record._id), job: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Job"
    end
  end

  describe "delete job" do
    setup [:create_record]

    test "deletes chosen job", %{conn: conn, record: record} do
      conn = delete(conn, Routes.job_path(conn, :delete, record._id))
      assert redirected_to(conn) == Routes.job_path(conn, :index)

      conn = get(conn, Routes.job_path(conn, :show, record._id))
      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  defp create_record(_) do
    record = cloudant_insert(:job)

    {:ok, record: record}
  end
end
