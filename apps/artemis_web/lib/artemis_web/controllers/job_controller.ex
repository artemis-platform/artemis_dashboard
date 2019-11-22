defmodule ArtemisWeb.JobController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.EventLogsIndex,
    path: &Routes.job_path/3,
    permission: "jobs:list",
    resource_type: "Job"

  use ArtemisWeb.Controller.EventLogsShow,
    path: &Routes.job_event_log_path/4,
    permission: "jobs:show",
    resource_getter: &Artemis.GetJob.call!/2,
    resource_id: "job_id",
    resource_type: "Job",
    resource_variable: :job

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
      user = current_user(conn)
      job = GetJob.call!(id, user)
      related_jobs = get_related_jobs(job, user)

      render(conn, "show.html", job: job, related_jobs: related_jobs)
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

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "jobs:delete", fn ->
      {:ok, _job} = DeleteJob.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Job deleted successfully.")
      |> redirect(to: Routes.job_path(conn, :index))
    end)
  end

  # Helpers

  defp get_related_jobs(%{task_id: nil}, _), do: []

  defp get_related_jobs(job, user) do
    params = %{
      filters: %{task_id: job.task_id},
      paginate: false,
      page_size: 1_000_000
    }

    params
    |> ListJobs.call(user)
    |> Map.get(:entries, [])
  end
end
