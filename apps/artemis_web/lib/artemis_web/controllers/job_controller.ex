defmodule ArtemisWeb.JobController do
  use ArtemisWeb, :controller
  use ArtemisWeb.Controller.Behaviour.EventLogs

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

  def delete(conn, %{"id" => id}) do
    authorize(conn, "jobs:delete", fn ->
      {:ok, _job} = DeleteJob.call(id, current_user(conn))

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

  # Callbacks - Event Logs

  def index_event_log_list(conn, params) do
    authorize(conn, "jobs:list", fn ->
      options = [
        path: &ArtemisWeb.Router.Helpers.job_path/3,
        resource_type: "Job"
      ]

      assigns = get_assigns_for_index_event_log_list(conn, params, options)

      render_format_for_event_log_list(conn, "index/event_log_list.html", assigns)
    end)
  end

  def index_event_log_details(conn, %{"id" => id}) do
    authorize(conn, "jobs:list", fn ->
      event_log = ArtemisLog.GetEventLog.call!(id, current_user(conn))

      render(conn, "index/event_log_details.html", event_log: event_log)
    end)
  end

  def show_event_log_list(conn, params) do
    authorize(conn, "jobs:show", fn ->
      job_id = Map.get(params, "job_id")
      job = GetJob.call!(job_id, current_user(conn))

      options = [
        path: &ArtemisWeb.Router.Helpers.job_event_log_path/4,
        resource_id: job_id,
        resource_type: "Job"
      ]

      assigns =
        conn
        |> get_assigns_for_show_event_log_list(params, options)
        |> Keyword.put(:job, job)

      render_format_for_event_log_list(conn, "show/event_log_list.html", assigns)
    end)
  end

  def show_event_log_details(conn, params) do
    authorize(conn, "jobs:show", fn ->
      job_id = Map.get(params, "job_id")
      job = GetJob.call!(job_id, current_user(conn))

      event_log_id = Map.get(params, "id")
      event_log = ArtemisLog.GetEventLog.call!(event_log_id, current_user(conn))

      assigns = [
        job: job,
        event_log: event_log
      ]

      render(conn, "show/event_log_details.html", assigns)
    end)
  end
end
