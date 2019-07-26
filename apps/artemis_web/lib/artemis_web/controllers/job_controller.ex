defmodule ArtemisWeb.JobController do
  use ArtemisWeb, :controller

  alias Artemis.CreateJob
  alias Artemis.DeleteJob
  alias Artemis.GetJob
  alias Artemis.Job
  alias Artemis.ListJobs
  alias Artemis.UpdateJob

  def index(conn, params) do
    authorize(conn, "jobs:list", fn ->
      params = Map.put(params, :paginate, true)
      jobs = ListJobs.call(params, current_user(conn))
      search_enabled = Job.search_enabled?()

      render_format(conn, "index", jobs: jobs, search_enabled: search_enabled)
    end)
  end

  def new(conn, _params) do
    authorize(conn, "jobs:create", fn ->
      job = %Job{raw_data: %{}}
      changeset = Job.changeset(job)

      render(conn, "new.html", changeset: changeset, job: job)
    end)
  end

  def create(conn, %{"job" => params}) do
    authorize(conn, "jobs:create", fn ->
      case CreateJob.call(params, current_user(conn)) do
        {:ok, job} ->
          conn
          |> put_flash(:info, "Job created successfully.")
          |> redirect(to: Routes.job_path(conn, :show, job._id))

        {:error, %Ecto.Changeset{} = changeset} ->
          job = %Job{raw_data: %{}}

          render(conn, "new.html", changeset: changeset, job: job)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "jobs:show", fn ->
      job = GetJob.call!(id, current_user(conn))

      render(conn, "show.html", job: job)
    end)
  rescue
    _ in Artemis.Context.Error -> render_not_found(conn)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "jobs:update", fn ->
      job = GetJob.call!(id, current_user(conn))
      changeset = Job.changeset(job)

      render(conn, "edit.html", changeset: changeset, job: job)
    end)
  end

  def update(conn, %{"id" => id, "job" => params}) do
    authorize(conn, "jobs:update", fn ->
      case UpdateJob.call(id, params, current_user(conn)) do
        {:ok, job} ->
          conn
          |> put_flash(:info, "Job updated successfully.")
          |> redirect(to: Routes.job_path(conn, :show, job._id))

        {:error, %Ecto.Changeset{} = changeset} ->
          job = GetJob.call(id, current_user(conn))

          render(conn, "edit.html", changeset: changeset, job: job)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    authorize(conn, "jobs:delete", fn ->
      {:ok, _job} = DeleteJob.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Job deleted successfully.")
      |> redirect(to: Routes.job_path(conn, :index))
    end)
  end
end
