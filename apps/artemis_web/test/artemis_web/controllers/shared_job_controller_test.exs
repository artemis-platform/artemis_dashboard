defmodule ArtemisWeb.SharedJobControllerTest do
  use ArtemisWeb.ConnCase

  import Artemis.Factories

  @create_attrs %{name: "New Name", status: "Pending"}
  @update_attrs %{name: "Updated Name", status: "Completed"}
  @invalid_attrs %{raw_data: "{"}

  setup %{conn: conn} do
    {:ok, conn: sign_in(conn)}
  end

  describe "index" do
    test "lists all shared jobs", %{conn: conn} do
      conn = get(conn, Routes.shared_job_path(conn, :index))
      assert html_response(conn, 200) =~ "Shared Jobs"
    end
  end

  describe "new shared job" do
    test "renders new form", %{conn: conn} do
      conn = get(conn, Routes.shared_job_path(conn, :new))
      assert html_response(conn, 200) =~ "New Shared Job"
    end
  end

  describe "create shared job" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.shared_job_path(conn, :create), shared_job: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.shared_job_path(conn, :show, id)

      conn = get(conn, Routes.shared_job_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.shared_job_path(conn, :create), shared_job: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Shared Job"
    end
  end

  describe "show" do
    setup [:create_record]

    test "shows shared job", %{conn: conn, record: record} do
      conn = get(conn, Routes.shared_job_path(conn, :show, record._id))
      assert html_response(conn, 200) =~ "Name"
    end
  end

  describe "edit shared job" do
    setup [:create_record]

    test "renders form for editing chosen shared job", %{conn: conn, record: record} do
      conn = get(conn, Routes.shared_job_path(conn, :edit, record._id))
      assert html_response(conn, 200) =~ "Edit Shared Job"
    end
  end

  describe "update shared job" do
    setup [:create_record]

    test "redirects when data is valid", %{conn: conn, record: record} do
      conn = put(conn, Routes.shared_job_path(conn, :update, record._id), shared_job: @update_attrs)
      assert redirected_to(conn) == Routes.shared_job_path(conn, :show, record._id)

      conn = get(conn, Routes.shared_job_path(conn, :show, record._id))
      assert html_response(conn, 200) =~ "Updated Name"
    end

    test "renders errors when data is invalid", %{conn: conn, record: record} do
      conn = put(conn, Routes.shared_job_path(conn, :update, record._id), shared_job: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Shared Job"
    end
  end

  describe "delete shared job" do
    setup [:create_record]

    test "deletes chosen shared job", %{conn: conn, record: record} do
      conn = delete(conn, Routes.shared_job_path(conn, :delete, record._id))
      assert redirected_to(conn) == Routes.shared_job_path(conn, :index)

      conn = get(conn, Routes.shared_job_path(conn, :show, record._id))
      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  defp create_record(_) do
    record = cloudant_insert(:shared_job)

    {:ok, record: record}
  end
end
