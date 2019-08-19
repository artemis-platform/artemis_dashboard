defmodule ArtemisWeb.ViewHelper.Presence do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Render presence list
  """
  def render_presence(conn) do
    user = current_user(conn)

    Phoenix.LiveView.live_render(
      conn,
      ArtemisWeb.PresenceLive,
      session: %{
        current_user: user,
        request_path: conn.request_path
      }
    )
  end
end
