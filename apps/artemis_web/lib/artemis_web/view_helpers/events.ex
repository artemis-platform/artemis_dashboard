defmodule ArtemisWeb.ViewHelper.Events do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Render event log notifier
  """
  def render_event_log_notifications(conn, type, id) do
    user = current_user(conn)

    Phoenix.LiveView.live_render(
      conn,
      ArtemisWeb.EventLogNotificationsLive,
      session: %{
        current_user: user,
        resource_id: id,
        resource_type: type
      }
    )
  end
end
