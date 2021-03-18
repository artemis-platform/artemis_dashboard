defmodule ArtemisWeb.ViewHelper.Notifications do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Generates a notification
  """
  def render_notification(type, params \\ []) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "notification_#{type}.html", params)
  end

  @doc """
  Generates a notification. See `render_notification/2`.
  """
  def render_notification(type, params, do: block) do
    params = Keyword.put(params, :do, block)

    render_notification(type, params)
  end

  @doc """
  Generates flash notifications
  """
  def render_flash_notifications(%Plug.Conn{} = conn) do
    Phoenix.View.render(ArtemisWeb.LayoutView, "flash_notifications.html", conn: conn)
  end

  def render_flash_notifications(_), do: nil

  @doc """
  Render event log notifier
  """
  def render_event_log_notifications(conn_or_assigns, type, id \\ nil)

  def render_event_log_notifications(%Plug.Conn{} = conn, type, id) do
    assigns = %{
      conn: conn,
      user: current_user(conn)
    }

    render_event_log_notifications(assigns, type, id)
  end

  def render_event_log_notifications(assigns, type, id) do
    conn_or_socket = Map.get(assigns, :conn) || Map.get(assigns, :socket)
    user = Map.get(assigns, :user)

    Phoenix.LiveView.Helpers.live_render(
      conn_or_socket,
      ArtemisWeb.EventLogNotificationsLive,
      id: :event_log_notifications,
      session: %{
        "current_user" => user,
        "resource_id" => id,
        "resource_type" => type
      }
    )
  end

  @doc """
  Render comment notifier
  """
  def render_comment_notifications(conn, type, id \\ nil, path) do
    user = current_user(conn)

    Phoenix.LiveView.Helpers.live_render(
      conn,
      ArtemisWeb.CommentNotificationsLive,
      session: %{
        "current_user" => user,
        "path" => path,
        "resource_id" => id,
        "resource_type" => type
      }
    )
  end
end
