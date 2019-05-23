defmodule ArtemisWeb.IncidentCommentController do
  use ArtemisWeb, :controller

  alias Artemis.Comment
  alias Artemis.CreateComment
  alias Artemis.GetComment
  alias Artemis.GetIncident
  alias Artemis.DeleteComment
  alias Artemis.Incident
  alias Artemis.ListComments
  alias Artemis.ListTags
  alias Artemis.UpdateComment

  @preload []

  def create(conn, %{"comment" => params, "incident_id" => incident_id}) do
    authorize(conn, "incidents:create:comments", fn ->
      incident = GetIncident.call!(incident_id, current_user(conn))
      user = current_user(conn)

      params =
        params
        |> Map.put("user_id", user.id)
        |> Map.put("incidents", [%{id: incident.id}])

      case CreateComment.call(params, user) do
        {:ok, _comment} ->
          conn
          |> put_flash(:info, "Comment created successfully.")
          |> redirect(to: Routes.incident_path(conn, :show, incident))

        {:error, %Ecto.Changeset{} = comment_changeset} ->
          comments = ListComments.call(%{filters: %{incident_id: incident.id}}, user)
          tags = ListTags.call(%{filters: %{type: "incidents"}}, user)
          tags_changeset = Incident.changeset(%Incident{})

          conn
          |> put_view(ArtemisWeb.IncidentView)
          |> render(:show,
            comment_changeset: comment_changeset,
            comments: comments,
            incident: incident,
            tags: tags,
            tags_changeset: tags_changeset
          )
      end
    end)
  end

  def edit(conn, %{"id" => id, "incident_id" => incident_id}) do
    authorize(conn, "incidents:update:comments", fn ->
      incident = GetIncident.call(incident_id, current_user(conn))
      comment = GetComment.call(id, current_user(conn), preload: @preload)
      changeset = Comment.changeset(comment)

      render(conn, "edit.html", changeset: changeset, comment: comment, incident: incident)
    end)
  end

  def update(conn, %{"comment" => params, "id" => id, "incident_id" => incident_id}) do
    authorize(conn, "incidents:update:comments", fn ->
      user = current_user(conn)
      incident = GetIncident.call!(incident_id, user)

      params =
        params
        |> Map.put("user_id", user.id)
        |> Map.put("incidents", [%{id: incident.id}])

      case UpdateComment.call(id, params, user) do
        {:ok, _comment} ->
          conn
          |> put_flash(:info, "Comment updated successfully.")
          |> redirect(to: Routes.incident_path(conn, :show, incident))

        {:error, %Ecto.Changeset{} = changeset} ->
          comment = GetComment.call(id, user)

          render(conn, "edit.html", changeset: changeset, comment: comment, incident: incident)
      end
    end)
  end

  def delete(conn, %{"id" => id, "incident_id" => incident_id}) do
    authorize(conn, "incidents:delete:comments", fn ->
      incident = GetIncident.call!(incident_id, current_user(conn))
      {:ok, _comment} = DeleteComment.call(id, current_user(conn))

      conn
      |> put_flash(:info, "Comment deleted successfully.")
      |> redirect(to: Routes.incident_path(conn, :show, incident))
    end)
  end
end
