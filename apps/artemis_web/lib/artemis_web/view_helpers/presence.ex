defmodule ArtemisWeb.ViewHelper.Presence do
  use Phoenix.HTML

  import ArtemisWeb.Guardian.Helpers

  @doc """
  Render user presence
  """
  def render_presence(conn) do
    user = current_user(conn)

    content_tag(:div, class: "presence") do
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

  @doc """
  Render a list of presence users
  """
  def render_presence_user_list(users) do
    content_tag(:ul, class: "presence-users") do
      Enum.map(users, fn user ->
        content_tag(:li) do
          user.name
        end
      end)
    end
  end
end
