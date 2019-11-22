defmodule ArtemisWeb.IncidentController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.IncidentView.available_bulk_actions(),
    path: &Routes.incident_path(&1, :index),
    permission: "incidents:list"

  alias Artemis.Comment
  alias Artemis.DeleteIncident
  alias Artemis.GetIncident
  alias Artemis.Incident
  alias Artemis.ListComments
  alias Artemis.ListIncidents

  def index(conn, params) do
    authorize(conn, "incidents:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, [:tags])

      incidents = ListIncidents.call(params, current_user(conn))
      tags = get_tags("incidents", user)

      render(conn, "index.html", incidents: incidents, tags: tags)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "incidents:show", fn ->
      user = current_user(conn)
      comments = ListComments.call(%{filters: %{incident_id: id}}, user)
      comment_changeset = Comment.changeset(%Comment{})
      incident = GetIncident.call!(id, user)
      tags = get_tags("incidents", user)
      tags_changeset = Incident.changeset(%Incident{})

      render(conn, "show.html",
        comment_changeset: comment_changeset,
        comments: comments,
        incident: incident,
        tags: tags,
        tags_changeset: tags_changeset
      )
    end)
  end

  def delete(conn, %{"id" => id} = params) do
    authorize(conn, "incidents:delete", fn ->
      {:ok, _incident} = DeleteIncident.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Incident deleted successfully.")
      |> redirect(to: Routes.incident_path(conn, :index))
    end)
  end
end
