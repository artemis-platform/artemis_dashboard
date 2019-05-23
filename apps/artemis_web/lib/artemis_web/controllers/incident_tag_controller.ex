defmodule ArtemisWeb.IncidentTagController do
  use ArtemisWeb, :controller

  alias Artemis.GetIncident
  alias Artemis.UpdateIncident

  def update(conn, %{"incident" => params, "incident_id" => incident_id}) do
    authorize(conn, "incidents:update:tags", fn ->
      user = current_user(conn)
      incident = GetIncident.call!(incident_id, user)

      params =
        incident
        |> Map.from_struct()
        |> Map.put(:tags, tag_params(params, "incidents", user))

      case UpdateIncident.call(incident_id, params, user) do
        {:ok, incident} ->
          conn
          |> put_flash(:info, "Tags updated successfully.")
          |> redirect(to: Routes.incident_path(conn, :show, incident))

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "Error updating tags.")
          |> put_view(ArtemisWeb.IncidentView)
          |> render(:show, changeset: changeset, incident: incident)
      end
    end)
  end
end
