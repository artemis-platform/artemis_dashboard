defmodule ArtemisWeb.IncidentController do
  use ArtemisWeb, :controller

  use ArtemisWeb.Controller.BulkActions,
    bulk_actions: ArtemisWeb.IncidentView.available_bulk_actions(),
    path: &Routes.incident_path(&1, :index),
    permission: "incidents:list"

  use ArtemisWeb.Controller.CommentsShow,
    path: &Routes.incident_path/3,
    permission: "incidents:show",
    resource_getter: &Artemis.GetIncident.call!/2,
    resource_id_key: "incident_id",
    resource_type: "Incident"

  alias Artemis.DeleteIncident
  alias Artemis.GetIncident
  alias Artemis.Incident
  alias Artemis.ListIncidents

  def index(conn, params) do
    authorize(conn, "incidents:list", fn ->
      user = current_user(conn)

      params =
        params
        |> Map.put(:paginate, true)
        |> Map.put(:preload, [:tags])

      incidents = ListIncidents.call(params, user)
      tags = get_tags("incidents", user)
      allowed_bulk_actions = ArtemisWeb.IncidentView.allowed_bulk_actions(user)

      assigns = [
        allowed_bulk_actions: allowed_bulk_actions,
        incidents: incidents,
        tags: tags
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "incidents:show", fn ->
      user = current_user(conn)
      incident = GetIncident.call!(id, user)
      tags = get_tags("incidents", user)
      tags_changeset = Incident.changeset(%Incident{})

      render(conn, "show.html",
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
