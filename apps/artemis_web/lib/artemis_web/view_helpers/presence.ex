defmodule ArtemisWeb.ViewHelper.Presence do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Render user presence
  """
  def render_presence(%{request_path: request_path, socket: socket, user: user}) do
    render_presence(socket, request_path, user)
  end

  def render_presence(%{conn: conn}) do
    render_presence(conn)
  end

  def render_presence(%Plug.Conn{} = conn) do
    render_presence(conn, conn.request_path, current_user(conn))
  end

  def render_presence(conn_or_socket, request_path, user) do
    content_tag(:div, class: "presence") do
      Phoenix.LiveView.Helpers.live_render(
        conn_or_socket,
        ArtemisWeb.PresenceLive,
        id: :presence,
        session: %{
          "current_user" => user,
          "request_path" => request_path
        }
      )
    end
  end
end
