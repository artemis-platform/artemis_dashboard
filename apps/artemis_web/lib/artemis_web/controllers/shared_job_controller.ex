defmodule ArtemisWeb.SharedJobController do
  use ArtemisWeb, :controller

  alias Artemis.DeleteSharedJob
  alias Artemis.GetSharedJob
  alias Artemis.ListSharedJobs
  alias Artemis.SharedJob
  alias Artemis.UpdateSharedJob

  @cloudant_search_keys [:name, :uuid]

  def index(conn, params) do
    authorize(conn, "shared-jobs:list", fn ->
      params =
        params
        |> add_cloudant_search_param(@cloudant_search_keys)
        |> Map.put(:paginate, true)

      jobs = ListSharedJobs.call(params, current_user(conn))

      render(conn, "index.html", jobs: jobs)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "shared-jobs:show", fn ->
      job = GetSharedJob.call!(id, current_user(conn))

      render(conn, "show.html", job: job)
    end)
  end

  def edit(conn, %{"id" => id}) do
    authorize(conn, "shared-jobs:update", fn ->
      job = GetSharedJob.call!(id, current_user(conn))
      changeset = SharedJob.changeset(job)

      render(conn, "edit.html", changeset: changeset, job: job)
    end)
  end

  def update(conn, %{"id" => id, "shared_job" => params}) do
    authorize(conn, "shared-jobs:update", fn ->
      case UpdateSharedJob.call(id, params, current_user(conn)) do
        {:ok, job} ->
          conn
          |> put_flash(:info, "Job updated successfully.")
          |> redirect(to: Routes.shared_job_path(conn, :show, job._id))

        {:error, %Ecto.Changeset{} = changeset} ->
          job = GetSharedJob.call(id, current_user(conn))

          render(conn, "edit.html", changeset: changeset, job: job)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    authorize(conn, "shared-jobs:delete", fn ->
      {:ok, _shared_job} = DeleteSharedJob.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Job deleted successfully.")
      |> redirect(to: Routes.shared_job_path(conn, :index))
    end)
  end
end
